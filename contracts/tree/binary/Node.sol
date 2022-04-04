// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Merkle Tree Node structure.
struct Node {
    bytes32 digest;
    // Left child.
    bytes32 leftChildPtr;
    // Right child.
    bytes32 rightChildPtr;
}
