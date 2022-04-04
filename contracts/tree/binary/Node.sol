// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @notice Merkle Tree Node structure.
struct Node {
    bytes32 digest;
    // Left child.
    bytes32 leftChildPtr;
    // Right child.
    bytes32 rightChildPtr;
}
