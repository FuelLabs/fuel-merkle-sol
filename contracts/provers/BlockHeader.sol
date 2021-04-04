// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../types/BlockCommitment.sol";
import "../types/BlockHeader.sol";

/// @title Block header sanitizer.
library BlockHeaderProver {
    ///////////
    // Enums //
    ///////////

    /// @dev Used for finality assertion in proving.
    enum AssertFinalized {
        // Assert not finalized.
        NotFinalized,
        // Assert finalized.
        Finalized,
        // No finality assertion.
        None
    }

    /////////////
    // Methods //
    /////////////

    /// @notice Prove a block header.
    /// @param s_BlockCommitments The block commitments storage pointer.
    /// @param finalizationDelay The block finalization delay.
    /// @param blockHeader The block header structure in memory.
    /// @param assertFinalized Enum flag of if the block should be finalized.
    function proveBlockHeader(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        BlockHeader memory blockHeader,
        AssertFinalized assertFinalized
    ) internal view {
        // Block must be known and valid (already committed).
        require(
            s_BlockCommitments[BlockLib.computeBlockId(blockHeader)].status ==
                BlockCommitmentStatus.Committed,
            "block-commitment"
        );

        // Check finalization assertion.
        if (assertFinalized == AssertFinalized.Finalized) {
            // If asserting finalized, block must be finalizable.
            require(block.number >= blockHeader.blockNumber + finalizationDelay, "not-finalized");
        } else if (assertFinalized == AssertFinalized.NotFinalized) {
            // If asserting not finalized, block must not be finalizable.
            require(block.number < blockHeader.blockNumber + finalizationDelay, "block-finalized");
        }
    }
}