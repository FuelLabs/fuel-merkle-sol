// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

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
    uint32 public constant MAX_TRANSACTION_IN_BLOCK = 32000;

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
        // Ensure the amount of transaction data is below the max block bound.
        require(
            blockHeader.transactionLength <= uint256(MAX_TRANSACTION_IN_BLOCK),
            "transactions-size-overflow"
        );

        // Ensure the digest length is below the max digest bound.
        require(blockHeader.digestLength < uint256(MAX_BLOCK_DIGESTS), "digest-length-overflow");

        // Block hash.
        bytes32 blockHash = BlockLib.computeBlockId(blockHeader);

        // Store block commitment.
        s_BlockCommitments[blockHeader.previousBlockHash].children.push(blockHash);

        // Emit the block committed event.
        emit BlockCommitted(
            blockHeader.previousBlockHash,
            blockHeader.height,
            blockHeader.producer,
            blockHeader
        );
    }
}
