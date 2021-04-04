// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./BlockHeader.sol";
import "../types/BlockCommitment.sol";
import "../types/BlockHeader.sol";
import "../lib/Block.sol";
import "../lib/Transaction.sol";

/// @title The Fuel block handler logic.
library BlockHandler {
    ///////////////
    // Constants //
    ///////////////

    // Maximum raw transaction data size in bytes.
    uint32 public constant MAX_COMPRESSED_TX_BYTES = 32000;

    // Maximum number of digests registered in a block.
    uint32 public constant MAX_BLOCK_DIGESTS = 0xFFFF;

    ////////////
    // Events //
    ////////////

    event BlockCommitted(
        bytes32 indexed previousBlockHash,
        uint32 indexed height,
        address indexed producer,
        BlockHeader block
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Commits a new rollup block.
    function commitBlock(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        BlockHeader memory blockHeader
    ) internal {
        // Bound maximum number of bytes for compressed transactions.
        require(
            blockHeader.transactionLength <= uint256(MAX_COMPRESSED_TX_BYTES),
            "transactions-size-overflow"
        );

        // Require that the digest length is at most the max digest bound.
        require(blockHeader.digestLength <= uint256(MAX_BLOCK_DIGESTS), "digest-length-overflow");

        // Require that genesis previous block is an empty hash.
        require(blockHeader.height > 0 || blockHeader.previousBlockHash == bytes32(0), "genesis");

        // Require that the previous block was committed.
        require(
            BlockHeaderHandler.isBlockCommitted(s_BlockCommitments, blockHeader.previousBlockHash),
            "not-committed"
        );

        // Compute the block ID.
        bytes32 blockId = BlockLib.computeBlockId(blockHeader);

        // Require that the current block is not committed.
        require(!BlockHeaderHandler.isBlockCommitted(s_BlockCommitments, blockId), "committed");

        // Set this block as committed.
        s_BlockCommitments[blockId].status = BlockCommitmentStatus.Committed;

        // Store block commitment as the latest direct child of the claimed parent.
        s_BlockCommitments[blockHeader.previousBlockHash].children.push(blockId);

        emit BlockCommitted(
            blockHeader.previousBlockHash,
            blockHeader.height,
            blockHeader.producer,
            blockHeader
        );
    }
}
