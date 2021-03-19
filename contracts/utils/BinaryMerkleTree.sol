// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

/// @notice This library will feature the logic for a verifiable (not updateable) Binary Sum Tree.
/// @dev Leafs will be prefixed with 0x00, and parent nodes with 0x01.
library BinaryMerkleTree {
    // updateable
    // verifiable
    // mountain range
    // could be updating lots of leafs (1-1k range).
    // Even (with zero leafs to make the tree balanced -- for rightmost checks).

    /////////////
    // Methods //
    /////////////

    /// @notice This will compute the root of a binary Merkle tree.
    /// @param leafs The leafs of the merkle tree.
    /// @return root The computed merkle root. 
    function computeRoot(bytes32[] calldata leafs) internal pure returns (bytes32 root) {
    }

    /// @notice Verify merkle proof and return rightmost.
    /// @dev Will verify a single leaf given a proof and merkle root.
    /// @param merkleTreeRoot The merkle root of the binary merkle tree.
    /// @param leaf The raw 32 btye leaf in question.
    /// @param bitmap The bitmap (e.g. "transaction index") of the proof.
    /// @param proof The set of bytes32 hashes for the proof.
    /// @return verified Is this proof a valid proof.
    function verifyWithRightmost(
        bytes32 merkleTreeRoot,
        bytes32 leaf,
        uint32 bitmap,
        bytes32[] memory proof
    ) internal pure returns (bool verified, bool rightmost) {
        // TODO: Remove.. This is just to silence the warning. To be removed in future.
        require(merkleTreeRoot != bytes32(0)
            && bytes32(leaf) == leaf
            && bitmap >= 0
            && proof.length > 0, "warning");

        // Return fill for now.
        return (true, false);
    }

    /// @notice Verify a leaf in a binary merkle tree.
    /// @dev Will verify a single leaf given a proof and merkle root.
    /// @param merkleTreeRoot The merkle root of the binary merkle tree.
    /// @param leaf The raw 32 btye leaf in question.
    /// @param bitmap The bitmap (e.g. "transaction index") of the proof.
    /// @param proof The set of bytes32 hashes for the proof.
    /// @return verified Is this proof a valid proof.
    function verify(
        bytes32 merkleTreeRoot,
        bytes32 leaf,
        uint32 bitmap,
        bytes32[] memory proof
    ) internal pure returns (bool verified) {
        // This is just to silence the warning. To be removed in future.
        require(merkleTreeRoot != bytes32(0)
            && bytes32(leaf) == leaf
            && bitmap >= 0
            && proof.length > 0, "warning");

        return true;
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

    /// @notice Compute an empty leaf node.
    /// @return node The empty leaf node in question.
    function computeEmptyLeafNode() internal pure returns (bytes32 node) {
        return sha256(abi.encodePacked(uint8(0), bytes32(0)));
    }
}