// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Sum Merkle Tree Proof structure.
struct SumMerkleProof {
    // List of side nodes to verify and calculate tree.
    bytes32[] sideNodes;
    // Node substree sums.
    uint256[] nodeSums;
}
