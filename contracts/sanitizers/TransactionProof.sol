// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./BlockHeader.sol";
import "./RootHeader.sol";
import "../lib/MerkleProof.sol";
import "../types/TransactionLeaf.sol";
import "../types/TransactionProof.sol";

/// @title Transaction proof sanitizer
library TransactionProofSanitizer {
    /////////////
    // Methods //
    /////////////

    /// @notice Sanitize a transaction proof.
    /// @param proof The transaction proof.
    /// @param assertFinalized Enum flag of if the block should be finalized.
    function sanitizeTransactionProof(
        mapping(uint32 => bytes32) storage s_BlockCommitments,
        uint32 finalizationDelay,
        TransactionProof calldata proof,
        BlockHeaderSanitizer.AssertFinalized assertFinalized
    ) internal view {
        // Sanitize the block header
        BlockHeaderSanitizer.sanitizeBlockHeader(
            s_BlockCommitments,
            finalizationDelay,
            proof.blockHeader,
            assertFinalized
        );
        // Sanitize the root header if needed
        if (proof.hasRootHeader) {
            RootHeaderSanitizer.sanitizeRootHeader(proof);
        }

        // Verify the Merkle inclusion proof
        require(
            MerkleProof.verify(
                proof.merkleProof,
                proof.rootHeader.merkleTreeRoot,
                keccak256(proof.transactionLeafBytes)
            )
        );

        // Transaction must be at least one byte long
        require(proof.transactionLeafBytes.length > 0, "empty-transaction");

        // Ensure the selector index is less than 8.
        require(proof.inputOutputIndex < 8, "index-overflow");
    }
}
