// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Transaction root header object. Contains Merkle tree root and important metadata.
struct RootHeader {
    // Address of root producer
    address producer;
    // Merkle root of list of transactions
    bytes32 merkleTreeRoot;
    // Simple hash of list of transactions
    bytes32 commitmentHash;
    // Length of list of transactions, in bytes
    uint32 length;
    // Token ID of all fees paid in this root
    uint32 feeToken;
    // Feerate of all fees paid in this root
    uint256 fee;
}
