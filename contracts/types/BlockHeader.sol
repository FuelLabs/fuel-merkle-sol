// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice The Fuel block header structure.
struct BlockHeader {
    // Address of block proposer committing this rollup block.
    address producer;
    // The root of the MMR of block header hashes, as of the most recent block
    bytes32 previousBlockRoot;
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
    // The root digest of the Merkle sum tree of uncompressed transactions.
    bytes32 transactionRoot;
    // The root sum of the Merkle sum tree of uncompressed transactions
    uint256 transactionSum;
    // Simple hash of list of transactions.
    bytes32 transactionHash;
    // Number of transactions in this block.
    uint32 numTransactions;
    // Length of (concatenated) compressed transactions in the block
    uint32 transactionsDataLength;
    // The hash of the abi-encoded validator set for the next block {address, stake}
    bytes32 validatorSetHash;
    // The stake required to validate this block
    uint256 requiredStake;
    // The root of the binary Merkle tree of withdrawal IDs in the block
    bytes32 withdrawalsRoot;
}
