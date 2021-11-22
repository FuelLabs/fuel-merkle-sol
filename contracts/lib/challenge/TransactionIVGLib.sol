// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../Cryptography.sol";
import "../tree/sum/TreeHasher.sol";
import "./ChallengeLib.sol";
import "./ChessClockLib.sol";
import "../../types/Transaction.sol";
import "./TransactionSerializationLib.sol";

/// @notice The state of a transaction IVG
struct TxGame {
    RequestedNode requestedNode;
    RevealedNode revealedNode;
    bool leafFound;
    bytes32 uncompressedDataHash;
    bytes32 compressedDataHash;
    bytes32 transactionHash;
    uint256 transactionsDataLength;
}

/// @notice The node revealed by the challenged
struct RevealedNode {
    bool isLeaf;
    bytes32 leftDigest;
    bytes32 rightDigest;
    uint256 leftSum;
    uint256 rightSum;
    uint256 dataStart;
    uint256 midpoint; // Data is implicitly contiguous if we define L and R as data[dataStart : midpoint] and data[midpoint : dataEnd]
    uint256 dataEnd;
    bytes leafData; // The uncompressed leaf data. Is "" unless isLeaf is true
    uint256 leafValue;
}

/// @notice The node requested by the challenger
struct RequestedNode {
    bool side;
    bytes32 digest;
    uint256 sum;
}

/// @notice This contract implements the transaction IVG, used to force a dishonest block proposer to reveal a transaction.
library TransactionIVGLib {
    /// @notice Reveal the node requested by the challenger
    /// @param challenge: The game being played
    /// @param node : The node to reveal
    function revealData(Challenge storage challenge, RevealedNode memory node) external {
        require(!challenge.transactionRevealed, "Tx IVG already completed");
        require(msg.sender == challenge.challenged, "Sender is not challenged");
        require(challenge.clock.position == ClockPosition.tick, "Not challenged's turn");

        TxGame storage game = challenge.txgame;

        // If revealing the root (first reveal, so left/right digests are 0), check data goes from 0 to len(transactions)
        if (game.revealedNode.leftDigest == bytes32(0)) {
            require(
                node.dataStart == 0 && node.dataEnd == game.transactionsDataLength,
                "Incorrect data length"
            );
        }

        // If revealing an intermediate node, check slices are consistent with the slices of the parent node
        if (game.revealedNode.leftDigest != bytes32(0)) {
            if (game.requestedNode.side) {
                require(
                    node.dataEnd == game.revealedNode.dataEnd &&
                        node.dataStart == game.revealedNode.midpoint,
                    "Inconsistent with last slices"
                );
            } else {
                require(
                    node.dataStart == game.revealedNode.dataStart &&
                        node.dataEnd == game.revealedNode.midpoint,
                    "Inconsistent with last slices"
                );
            }
        }

        // In all cases, the midpoint must be between the start and the end
        require(node.dataStart < node.midpoint && node.midpoint < node.dataEnd, "Invalid midpoint");

        // If node revealed is not a leaf
        if (!node.isLeaf) {
            // Check sums and digests are correct for the requested node
            require(
                nodeDigest(node.leftSum, node.leftDigest, node.rightSum, node.rightDigest) ==
                    game.requestedNode.digest,
                "Incorrect node digest"
            );
            require(node.leftSum + node.rightSum == game.requestedNode.sum, "Incorrect node sum");
        }
        // If node revealed is a leaf
        else {
            // Check leaf value and data are correct for the requested node
            require(
                leafDigest(node.leafValue, node.leafData) == game.requestedNode.digest,
                "Incorrect leaf digest"
            );
            require(node.leafValue == game.requestedNode.sum, "Incorrect leaf value");
            game.leafFound = true;

            // If we're at a leaf, we save the hash of the data, which will be re-provided
            // later in the form of a Transaction struct, and set the node.leafData to [] so that the
            // remainder of the node can be saved.
            game.uncompressedDataHash = CryptographyLib.hash(node.leafData);
            node.leafData = "";
        }

        // Save the node
        game.revealedNode = node;
    }

    /// @notice Request a child of the last revealed node
    /// @param challenge : The game being played
    /// @param rightSide : The child being requested. true = right, false = left.
    function requestData(Challenge storage challenge, bool rightSide) external {
        require(!challenge.transactionRevealed, "Tx IVG already completed");
        require(msg.sender == challenge.challenger, "Sender is not challenger");
        require(challenge.clock.position == ClockPosition.tock, "Not challenger's turn");

        TxGame storage game = challenge.txgame;

        require(!game.leafFound, "Leaf already found");

        if (rightSide) {
            game.requestedNode = RequestedNode(
                true,
                game.revealedNode.rightDigest,
                game.revealedNode.rightSum
            );
        } else {
            game.requestedNode = RequestedNode(
                false,
                game.revealedNode.leftDigest,
                game.revealedNode.leftSum
            );
        }
    }

    /// @notice Once a leaf has been revealed, get its uncompressed data using the slice provided
    /// @param challenge: The game being played
    /// @param compressedTxData: The byte array of all the compressed transaction in the block
    function sliceTransactionData(Challenge storage challenge, bytes calldata compressedTxData)
        external
    {
        require(!challenge.transactionRevealed, "Tx IVG already completed");
        require(msg.sender == challenge.challenger, "Sender is not challenger");
        require(challenge.clock.position == ClockPosition.tock, "Not challenger's turn");

        TxGame storage game = challenge.txgame;
        require(game.leafFound, "Game not yet arrived at leaf");

        // Check the compressed transaction data provided is correct (hashes to block.transactionHash)
        require(
            CryptographyLib.hash(compressedTxData) == game.transactionHash,
            "Incorrect compressed data"
        );

        // Slice the transaction using the indices provided by the challenged
        // : IVG has narrowed down to a single transaction, so midpoint is not used
        uint256 sliceStart = game.revealedNode.dataStart;
        uint256 sliceEnd = game.revealedNode.dataEnd;

        bytes calldata compressedTx = compressedTxData[sliceStart:sliceEnd];

        challenge.txgame.compressedDataHash = CryptographyLib.hash(compressedTx);
    }

    string internal constant COMPARE_ERROR = "compressed/uncompressed tx mismatch";

    function provideTransactions(
        Challenge storage challenge,
        Transaction memory compressedTx,
        Transaction memory uncompressedTx
    ) external {
        require(!challenge.transactionRevealed, "Transaction dispute not active");
        require(msg.sender == challenge.challenged, "Sender is not challenged");

        // Serialize the provided structs, checking correct transaction formation
        bytes memory serializedCompressedTx =
            TransactionSerializationLib.serializeTransaction(compressedTx, true);
        bytes memory serializedUncompressedTx =
            TransactionSerializationLib.serializeTransaction(uncompressedTx, true);

        // Check they match the digests from the Transaction IVG phase
        require(
            CryptographyLib.hash(serializedCompressedTx) == challenge.txgame.compressedDataHash,
            "bad compressed digest"
        );
        require(
            CryptographyLib.hash(serializedUncompressedTx) == challenge.txgame.uncompressedDataHash,
            "bad uncompressed digest"
        );

        // Check compressed and uncompressed transactions superficially match (otherwise reverts)
        compareTransactions(compressedTx, uncompressedTx);

        // Save hashes of abi-encoded transaction structs to storage for verification without serialization later on
        challenge.uncompressedTransactionHash = CryptographyLib.hash(abi.encode(uncompressedTx));
        challenge.compressedTransactionHash = CryptographyLib.hash(abi.encode(compressedTx));
        challenge.transactionRevealed = true;
    }

    /// @notice Check the compressed and uncompressed tx objects represent the same transaction
    /// @param tx1: The uncompressed transaction
    /// @param tx2: The compressed transaction
    /// @dev We compare all properties which are the same in a compressed and an uncompressed transaction
    function compareTransactions(Transaction memory tx1, Transaction memory tx2) internal pure {
        require(tx1.kind == tx2.kind, COMPARE_ERROR);
        require(tx1.gasPrice == tx2.gasPrice, COMPARE_ERROR);
        require(tx1.gasLimit == tx2.gasLimit, COMPARE_ERROR);
        require(tx1.maturity == tx2.maturity, COMPARE_ERROR);
        require(tx1.scriptLength == tx2.scriptLength, COMPARE_ERROR);
        require(keccak256(tx1.script) == keccak256(tx2.script), COMPARE_ERROR);
        require(tx1.scriptDataLength == tx2.scriptDataLength, COMPARE_ERROR);
        require(keccak256(tx1.scriptData) == keccak256(tx2.scriptData), COMPARE_ERROR);
        require(tx1.inputsCount == tx2.inputsCount, COMPARE_ERROR);
        require(tx1.outputsCount == tx2.outputsCount, COMPARE_ERROR);
        require(tx1.witnessesCount == tx2.witnessesCount, COMPARE_ERROR);

        // Compare each input, output & witness
        require(tx1.inputs.length == tx2.inputs.length, COMPARE_ERROR);
        for (uint256 i = 0; i < tx1.inputs.length; i += 1) {
            compareInput(tx1.inputs[i], tx2.inputs[i]);
        }

        require(tx1.outputs.length == tx2.outputs.length, COMPARE_ERROR);
        for (uint256 i = 0; i < tx1.outputs.length; i += 1) {
            compareOutput(tx1.outputs[i], tx2.outputs[i]);
        }

        require(tx1.witnesses.length == tx2.witnesses.length, COMPARE_ERROR);
        for (uint256 i = 0; i < tx1.witnesses.length; i += 1) {
            compareWitness(tx1.witnesses[i], tx2.witnesses[i]);
        }

        require(tx1.bytecodeLength == tx2.bytecodeLength, COMPARE_ERROR);
        require(tx1.bytecodeWitnessIndex == tx2.bytecodeWitnessIndex, COMPARE_ERROR);
        require(tx1.staticContractsCount == tx2.staticContractsCount, COMPARE_ERROR);
        require(tx1.salt == tx2.salt, COMPARE_ERROR);

        require(tx1.staticContracts.length == tx2.staticContracts.length, COMPARE_ERROR);
        for (uint256 i = 0; i < tx1.staticContracts.length; i += 1) {
            require(tx1.staticContracts[i] == tx2.staticContracts[i], COMPARE_ERROR);
        }
    }

    function compareInput(Input memory in1, Input memory in2) internal pure {
        require(in1.kind == in2.kind, COMPARE_ERROR);
        require(in1.witnessIndex == in2.witnessIndex, COMPARE_ERROR);
        require(in1.maturity == in2.maturity, COMPARE_ERROR);
        require(in1.predicateLength == in2.predicateLength, COMPARE_ERROR);
        require(in1.predicateDataLength == in2.predicateDataLength, COMPARE_ERROR);
        require(keccak256(in1.predicate) == keccak256(in2.predicate), COMPARE_ERROR);
        require(keccak256(in1.predicateData) == keccak256(in2.predicateData), COMPARE_ERROR);
    }

    function compareOutput(Output memory out1, Output memory out2) internal pure {
        require(out1.kind == out2.kind, COMPARE_ERROR);
        require(out1.inputIndex == out2.inputIndex, COMPARE_ERROR);
        require(out1.amount == out2.amount, COMPARE_ERROR);
    }

    function compareWitness(Witness memory wit1, Witness memory wit2) internal pure {
        require(wit1.dataLength == wit2.dataLength, COMPARE_ERROR);
        require(keccak256(wit2.data) == keccak256(wit2.data), COMPARE_ERROR);
    }
}
