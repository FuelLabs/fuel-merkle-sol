// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice Sum Merkle Tree Proof structure.
struct SumMerkleProof {
    // List of side nodes to verify and calculate tree.
    bytes32[] sideNodes;
    // Node substree sums.
    uint256[] nodeSums;
}
