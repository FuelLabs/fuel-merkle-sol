// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Sparse Merkle Tree Proof structure.
struct SparseMerkleProof {
    // List of side nodes to verify and calculate tree.
    bytes32[] sideNodes;
    // Node depth in sparse tree.
    uint256 depth;
    // Bitfield of explicitly included side nodes hashes.
    bytes32 includedNodes;
}
