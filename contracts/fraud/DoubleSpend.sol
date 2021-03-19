// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../provers/TransactionProof.sol";
import "../utils/BinaryMerkleTree.sol";
import "../handlers/Fraud.sol";
import "../types/TransactionProof.sol";

/// @title This is a single round fraud proof for invalid block digest registry.
library InvalidDoubleSpend {

    /////////////
    // Methods //
    /////////////

    /// @notice Prove that a block registry is invalid.
    /// @dev We will compute the merkle tree root, then compare against the committed root.
    function proveInvalidDoubleSpend(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        uint256 bondSize,
        address payable fraudCommitter,
        TransactionProof calldata fraudTx,
        TransactionProof calldata referencedTx
    ) internal {
        // Prove that the fraud tx exists and is not finalized.
        TransactionProofProver.proveTransactionProof(
            s_BlockCommitments,
            finalizationDelay,
            fraudTx,
            BlockHeaderProver.AssertFinalized.NotFinalized
        );

        // Prove that the reference tx exists.
        TransactionProofProver.proveTransactionProof(
            s_BlockCommitments,
            finalizationDelay,
            referencedTx,
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
        Input memory referenceInput = referencedTx.transaction.inputs[referencedTx.inputOutputIndex];

        // Compute root.
        if (fraudInput.utxoID == referenceInput.utxoID) {
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "double-spend"
            );
        }
    }
}