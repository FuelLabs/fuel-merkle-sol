// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../../../lib/Cryptography.sol";
import "../Constants.sol";
import "./Node.sol";

/// @notice hash some data
/// @param data: The data to be hashed
// solhint-disable-next-line func-visibility
function hash(bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(data);
}

/// @notice Calculate the digest of a node
/// @param left : The left child
/// @param right: The right child
/// @return digest : The node digest
// solhint-disable-next-line func-visibility
function nodeDigest(bytes32 left, bytes32 right) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.NODE_PREFIX, left, right));
}

/// @notice Calculate the digest of a leaf
/// @param data : The data of the leaf
/// @return digest : The leaf digest
// solhint-disable-next-line func-visibility
function leafDigest(bytes memory data) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.LEAF_PREFIX, data));
}

/// @notice Hash a leaf node.
/// @param data, raw data of the leaf.
/// @return The leaf represented as a Node struct
// solhint-disable-next-line func-visibility
function hashLeaf(bytes memory data) pure returns (Node memory) {
    bytes32 digest = leafDigest(data);
    return Node(digest, Constants.NULL, Constants.NULL);
}

/// @notice Hash a node, which is not a leaf.
/// @param left, left child hash.
/// @param right, right child hash.
/// @param leftPtr, the pointer to the left child
/// @param rightPtr, the pointer to the right child
/// @return : The new Node object
// solhint-disable-next-line func-visibility
function hashNode(
    bytes32 leftPtr,
    bytes32 rightPtr,
    bytes32 left,
    bytes32 right
) pure returns (Node memory) {
    bytes32 digest = nodeDigest(left, right);
    return Node(digest, leftPtr, rightPtr);
}

/// @notice Parse a node's data into its left and right children
/// @param node: The node to be parsed
/// @return : Pointers to the left and right children
// solhint-disable-next-line func-visibility
function parseNode(Node memory node) pure returns (bytes32, bytes32) {
    return (node.leftChildPtr, node.rightChildPtr);
}

/// @notice See if node has children, otherwise it is a leaf
/// @param node: The node to be parsed
/// @return : Whether the node is a leaf.
// solhint-disable-next-line func-visibility
function isLeaf(Node memory node) pure returns (bool) {
    return (node.leftChildPtr == Constants.ZERO || node.rightChildPtr == Constants.ZERO);
}
