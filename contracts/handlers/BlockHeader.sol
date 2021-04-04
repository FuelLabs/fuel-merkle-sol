// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../types/BlockCommitment.sol";
import "../types/BlockHeader.sol";

/// @title Block header handler.
library BlockHeaderHandler {
    /////////////
    // Methods //
    /////////////

    /// @notice Check if a block header has been committed.
    /// @param s_BlockCommitments The block commitments storage pointer.
    /// @param blockHeader The block header structure in memory.
    /// @return True if block header has been committed, false otherwise.
    function isBlockHeaderCommitted(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        BlockHeader memory blockHeader
    ) internal view returns (bool) {
        return
            s_BlockCommitments[BlockLib.computeBlockId(blockHeader)].status !=
            BlockCommitmentStatus.NotCommitted;
    }

    /// @notice Assert that a block header is finalizable.
    /// @param finalizationDelay The number of blocks required for a block to be finalizable.
    /// @param blockHeader The block header structure in memory.
    function requireBlockHeaderFinalizable(uint32 finalizationDelay, BlockHeader memory blockHeader)
        internal
        view
    {
        require(block.number >= blockHeader.blockNumber + finalizationDelay, "not-finalizable");
    }
}
