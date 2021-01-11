// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../types/TransactionProof.sol";
import "../types/BlockHeader.sol";

/// @title Block header sanitizer
library BlockHeaderSanitizer {
    enum AssertFinalized {
        // Assert not finalized
        NotFinalized,
        // Assert finalized
        Finalized,
        // No finality assertion
        None
    }

    /////////////
    // Methods //
    /////////////

    /// @notice Sanitize a block header.
    /// @param proof The transaction proof.
    /// @param assertFinalized Enum flag of if the block should be finalized.
    function sanitizeBlockHeader(
        mapping(uint32 => bytes32) storage s_BlockCommitments,
        uint32 finalizationDelay,
        TransactionProof calldata proof,
        AssertFinalized assertFinalized
    ) internal view {
        BlockHeader calldata blockHeader = proof.blockHeader;

        // Block must be known (already committed)
        require(
            s_BlockCommitments[blockHeader.height] ==
                keccak256(abi.encode(blockHeader)),
            "block-commitment"
        );

        if (assertFinalized == AssertFinalized.Finalized) {
            // If asserting finalized, block must be finalizable
            require(
                block.number >= blockHeader.blockNumber + finalizationDelay,
                "not-finalized"
            );
        } else if (assertFinalized == AssertFinalized.NotFinalized) {
            // If asserting not finalized, block must not be finalizable
            require(
                block.number < blockHeader.blockNumber + finalizationDelay,
                "block-finalized"
            );
        }
    }
}
