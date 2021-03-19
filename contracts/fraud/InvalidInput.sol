// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../provers/TransactionProof.sol";
import "../utils/BinaryMerkleTree.sol";
import "../handlers/Fraud.sol";
import "../types/TransactionProof.sol";

/// @title This is a single round fraud proof for invalid block digest registry.
library InvalidInput {

    /////////////
    // Methods //
    /////////////

    /// @notice Prove an invalid input reference.
    /// @dev Here we check for input reference overflow, existance etc.
    function proveInvalidInput(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        uint256 bondSize,
        address payable fraudCommitter,
        TransactionProof memory fraudTx,
        TransactionProof memory referencedTx
    ) internal {
        // Prove that the fraud tx exists and is not finalized.
        TransactionProofProver.proveTransactionProof(
            s_BlockCommitments,
            finalizationDelay,
            fraudTx,
            BlockHeaderProver.AssertFinalized.NotFinalized
        );

        // Align block header.
        BlockHeaderProver.proveBlockHeader(
            s_BlockCommitments,
            finalizationDelay,
            referencedTx.blockHeader,
            BlockHeaderProver.AssertFinalized.None
        );

        // Verify that the referenced block is in the merkle mountain range of the previous hash.
        require(BinaryMerkleTree.verify(
            fraudTx.blockHeader.previousBlockHash,
            BlockLib.computeBlockId(referencedTx.blockHeader),
            referencedTx.blockHeader.height,
            referencedTx.mmrMerkleProof
        ), "invalid-merkle-proof");

        // Compare UTXO id's.
        Input memory fraudInput = fraudTx.transaction.inputs[fraudTx.inputOutputIndex];

        // Require block height correct.
        require(
            fraudInput.pointer.blockHeight == referencedTx.blockHeader.height,
            "height-alignment"
        );

        // Now we check for rightmost.
        (bool merkleSuccess, bool rightmost) = BinaryMerkleTree.verifyWithRightmost(
            referencedTx.blockHeader.merkleTreeRoot,
            referencedTx.empty
                ? bytes32(0)
                : TransactionLib.computeTransactionId(referencedTx.transaction),
            referencedTx.transactionIndex,
            referencedTx.merkleProof
        );

        // Require success of merkle verification.
        require(merkleSuccess, "merkle-proof");

        // Handle rightmost overflow case.
        if (rightmost && fraudInput.pointer.txIndex > referencedTx.transactionIndex) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "tx-index-overflow"
            );
        }

        // Ensure transaction index alignment.
        require(
            fraudInput.pointer.txIndex == referencedTx.transactionIndex,
            "tx-index"
        );

        // Fraud if the referenced transaction is an empty leaf.
        if (referencedTx.empty == true) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "empty-transaction"
            );
        }

        // Check if the referenced transaction index overflows past tx bound.
        if (fraudInput.pointer.outputIndex >= referencedTx.transaction.outputs.length) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "output-index-overflow"
            );
        }

        // Check if the output index aligns.
        require(
            fraudInput.pointer.outputIndex == referencedTx.inputOutputIndex,
            "output-index"
        );

        // Check if withdraw or variable input spends.
        Output memory referencedOutput = referencedTx.transaction.outputs[
            referencedTx.inputOutputIndex
        ];

        // If the referenced input is a withdrawal, not possible.
        // TODO: variable input?
        if (referencedOutput.kind == OutputKind.Withdrawal) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "referenced-withdrawal"
            );
        }

        // If the kind is a Coin but doesn't referecnce a coin.
        if (fraudInput.kind == InputKind.Coin
            && referencedOutput.kind != OutputKind.Coin
            && referencedOutput.kind != OutputKind.Change) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "coin-reference"
            );
        }
    }
}
