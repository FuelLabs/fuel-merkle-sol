// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

/// @notice This library will feature the logic for a verifiable (not updateable) Binary Sum Tree.
/// @dev Leafs will be prefixed with 0x00, and parent nodes with 0x01.
library BinaryMerkleTree {
    // updateable
    // verifiable
    // mountain range
    // could be updating lots of leafs (1-1k range).

    /////////////
    // Methods //
    /////////////

    /// @notice This will compute the root of a binary Merkle tree.
    /// @param leafs The leafs of the merkle tree.
    /// @return root The computed merkle root. 
    function computeRoot(bytes32[] calldata leafs) internal pure returns (bytes32 root) {
    }

    /// @notice Compute a inner node of the Binary merkle tree.
    /// @param left The left node hash.
    /// @param right The right node hash.
    /// @return node The computed node hash.
    function computeInnerNode(bytes32 left, bytes32 right) internal pure returns (bytes32 node) {
        return sha256(abi.encodePacked(uint8(1), left, right));
    }

    /// @notice Compute a leaf node of the Binary merkle tree.
    /// @param leaf The leaf.
    /// @return node The computed node hash.
    function computeLeafNode(bytes32 leaf) internal pure returns (bytes32 node) {
        return sha256(abi.encodePacked(uint8(0), leaf));
    }
}