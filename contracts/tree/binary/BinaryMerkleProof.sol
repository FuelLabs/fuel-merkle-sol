// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @notice Merkle Tree Node structure.
struct BinaryMerkleProof {
    bytes32[] proof;
    uint256 key;
    uint256 numLeaves;
}
