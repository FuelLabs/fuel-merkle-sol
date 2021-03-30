// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice The Fuel block header structure.
struct BlockHeader {
    // Address of block proposer committing this rollup block.
    address producer;
    // Previous rollup block's header hash.
    bytes32 previousBlockHash;
    // Rollup block height.
    uint32 height;
    // Ethereum block number when this rollup block is committed.
    uint32 blockNumber;
    // Merkle root of digests registered in this block.
    bytes32 digestRoot;
    // Hash of digests registered in this block.
    bytes32 digestHash;
    // The number of registered digests.
    uint16 digestLength;
    // The Merkle root of a binary Merkle tree, where the leaves are the expanded transactions.
    bytes32 transactionRoot;
    // Simple hash of list of transactions.
    bytes32 commitmentHash;
    // Number of transactions in this block.
    uint32 transactionLength;
}
