// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/// @notice Merkle Tree Node structure.
struct BinaryMerkleProof {
    bytes32[] proof;
    uint256 key;
    uint256 numLeaves;
}
