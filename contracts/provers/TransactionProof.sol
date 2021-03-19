// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../types/BlockCommitment.sol";
import "../types/BlockHeader.sol";
import "../types/TransactionProof.sol";
import "./BlockHeader.sol";
import "../lib/Transaction.sol";
import "../utils/SafeCast.sol";
import "../utils/BinaryMerkleTree.sol";

/// @title Transaction proof sanitizer.
library TransactionProofProver {

    /////////////
    // Methods //
    /////////////

    /// @notice This will prove a transaction in a specific block.
    /// @param txProof The transaction proof in question.
    /// @param assertFinalized Enum flag of if the block/tx should be finalized.
    function proveTransactionProof(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        TransactionProof memory txProof,
        BlockHeaderProver.AssertFinalized assertFinalized
    ) internal view {
        // Requre the block header to be valid. 
        BlockHeaderProver.proveBlockHeader(
            s_BlockCommitments,
            finalizationDelay,
            txProof.blockHeader,
            assertFinalized
        );

        // The transaction id.
        bytes32 id = TransactionLib.computeTransactionId(txProof.transaction);

        // Verify the merkle proof.
        require(BinaryMerkleTree.verify(
            txProof.blockHeader.merkleTreeRoot,
            id,
            uint32(txProof.transactionIndex),
            txProof.merkleProof
        ), "invalid-merkle-proof");

        // Require that the leaf is not flag empty.
        require(txProof.empty == false, "empty-transaction");

        // Ensure the output index is less than max output bound.
        require(
            txProof.inputOutputIndex < TransactionLib.MAX_INPUTS,
            "input-output-overflow"
        );
    }
}