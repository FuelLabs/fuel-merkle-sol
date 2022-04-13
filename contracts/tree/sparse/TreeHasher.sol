// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../Cryptography.sol";
import "../Constants.sol";
import "./Node.sol";

/// @notice Contains functions for hashing leaves and nodes, and parsing their data

/// @notice hash some data
/// @param data: The data to be hashed
// solhint-disable-next-line func-visibility
function hash(bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(data);
}

// solhint-disable-next-line func-visibility
function nodeDigest(bytes32 left, bytes32 right) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.NODE_PREFIX, left, right));
}

// solhint-disable-next-line func-visibility
function leafDigest(bytes32 key, bytes memory value) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.LEAF_PREFIX, key, hash(value)));
}

/// @notice Hash a leaf node.
/// @param key: The key of the leaf
/// @param data, raw data of the leaf.
/// @return The leaf represented as a Node struct
// solhint-disable-next-line func-visibility
function hashLeaf(bytes32 key, bytes memory data) pure returns (Node memory) {
    bytes32 digest = leafDigest(key, data);
    return Node(digest, Constants.LEAF_PREFIX, Constants.NULL, Constants.NULL, key, data);
}

/// @notice Hash a node, which is not a leaf.
/// @param left, left child hash.
/// @param right, right child hash.
/// @param leftPtr, the pointer to the left child
/// @param rightPtr, the pointer to the right child
// solhint-disable-next-line func-visibility
function hashNode(
    bytes32 leftPtr,
    bytes32 rightPtr,
    bytes32 left,
    bytes32 right
) pure returns (Node memory) {
    bytes32 digest = nodeDigest(left, right);
    return Node(digest, Constants.NODE_PREFIX, leftPtr, rightPtr, Constants.NULL, "");
}

/// @notice Parse a node's data into its left and right children
/// @param node: The node to be parsed
// solhint-disable-next-line func-visibility
function parseNode(Node memory node) pure returns (bytes32, bytes32) {
    return (node.leftChildPtr, node.rightChildPtr);
}

/// @notice Parse a leaf's data into its key and data
/// @param leaf: The leaf to be parsed
// solhint-disable-next-line func-visibility
function parseLeaf(Node memory leaf) pure returns (bytes32, bytes memory) {
    return (leaf.key, leaf.leafData);
}

/// @notice Inspect the prefix of a node's data to determine if it is a leaf
/// @param node: The node to be parsed
// solhint-disable-next-line func-visibility
function isLeaf(Node memory node) pure returns (bool) {
    return (node.prefix == Constants.LEAF_PREFIX);
}
