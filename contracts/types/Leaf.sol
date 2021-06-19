// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Merkle Tree Leaf metadata
struct Leaf {
    // Hash of leaf
    bytes32 leafHash;
    // Height of leaf in tree
    uint256 height;
}
