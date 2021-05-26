// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Node.sol";
import "./Leaf.sol";

/// @notice BinaryMerkleTree structure.
struct MerkleTree {
    // Mapping hash => node.
    mapping(bytes32 => Node) nodes;
    // Mapping key => leaf
    mapping(uint256 => Leaf) leaves;
    // Merkle tree root.
    bytes32 root;
}
