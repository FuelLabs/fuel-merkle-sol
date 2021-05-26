// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Merkle Tree Node structure.
struct Node {
    // Left child.
    bytes32 left;
    // Right child.
    bytes32 right;
    // Parent
    bytes32 parent;
}
