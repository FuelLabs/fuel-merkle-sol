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
    // Digest registry merkle root.
    bytes32 digestRoot;
    // Hash of digests registered in this block.
    bytes32 digestHash;
    // The length of the provided digests.
    uint16 digestLength;
    // The merkle root of a binary merkle tree, where the leafs are hashes of the uncompressed transactions.
    bytes32 transactionRoot;
    // Simple hash of list of transactions.
    bytes32 commitmentHash;
    // Length of list of transactions, in bytes.
    uint32 transactionLength;
}
