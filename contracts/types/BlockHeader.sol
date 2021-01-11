// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Block header object
struct BlockHeader {
    // Address of block proposer committing this rollup block
    address producer;
    // Previous rollup block's header hash
    bytes32 previousBlockHash;
    // Rollup block height
    uint32 height;
    // Ethereum block number when this rollup block is committed
    uint32 blockNumber;
    // Maximum token ID used in this rollup block + 1
    uint32 numTokens;
    // Maximum address ID used in this rollup block + 1
    uint32 numAddresses;
    // List of transaction roots. Each root is the Merkle root of a list of transactions.
    bytes32[] roots;
}
