// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/BinaryMerkleTree.sol";
import "../types/BinaryMerkleProof.sol";
import "../types/MerkleTree.sol";

/// @title Mock for binary Merkle tree.
contract MockBinaryMerkleTree {
    using BinaryMerkleTree for MerkleTree;

    MerkleTree public merkleTree;
    uint256 public nBranches;

    /// @notice Set root for the Merkle tree.
    function setRoot(bytes32 root) external {
        merkleTree.setRoot(root);
    }

    /// @notice Computes binary Merkle tree root from full set of leaves.
    function computeRoot(bytes[] memory data) external pure returns (bytes32) {
        return BinaryMerkleTree.computeRoot(data);
    }

    /// @notice Verify if element (key, data) exists in Merkle tree, given data, proof, and root.
    /// @dev Pure function
    function verify(
        bytes32 root,
        bytes memory data,
        BinaryMerkleProof memory proof,
        uint256 key,
        uint256 numLeaves
    ) external pure returns (bool) {
        return BinaryMerkleTree.verify(root, data, proof, key, numLeaves);
    }

    /// @notice Calculates the new root when a new leaf is appended to the tree.
    /// @dev Pure function
    function append(
        uint256 numLeaves,
        bytes memory data,
        BinaryMerkleProof memory proof
    ) external pure returns (bytes32, bool) {
        return BinaryMerkleTree.append(numLeaves, data, proof);
    }

    /// @notice Adds a branch to the in-storage sparse representation of tree
    function addBranch(
        uint256 key,
        bytes memory data,
        BinaryMerkleProof memory proof,
        uint256 numLeaves
    ) external {
        merkleTree.addBranch(key, data, proof, numLeaves);
        nBranches += 1;
    }

    /// @notice Changes the data at a given leaf in the tree, and calculates the root
    function update(uint256 key, bytes memory data) external returns (bytes32 newRoot) {
        newRoot = merkleTree.update(key, data);
    }

    /// @notice For testing: expose the nodes do we can get the node at a given hash
    function getNode(bytes32 _hash) public view returns (Node memory) {
        return merkleTree.nodes[_hash];
    }

    /// @notice For testing: expose the root.
    /// @dev this.merkleRoot also returns the root, but is less readable
    function getRoot() public view returns (bytes32) {
        return merkleTree.root;
    }
}
