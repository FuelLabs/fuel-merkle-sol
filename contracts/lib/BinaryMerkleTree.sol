//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../lib/Cryptography.sol";
import "../types/BinaryMerkleProof.sol";
import "../types/MerkleTree.sol";
import "../types/Node.sol";
import "./constants.sol";

/// @title Binary Merkle Tree.
/// @notice spec can be found at https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/cryptographic_primitives.md#binary-merkle-tree.
library BinaryMerkleTree {
    ///////////////
    // Libraries //
    ///////////////
    using SafeMath for uint256;

    ////////////////
    //   Methods  //
    ////////////////
    /// @notice Set root for the Merkle tree.
    /// @param merkleTree, MerkleTree struct, Merkle Tree for which to set root.
    /// @param newRoot, which is to set as Merkle tree root.
    function setRoot(MerkleTree storage merkleTree, bytes32 newRoot) internal {
        merkleTree.root = newRoot;
    }

    /// @notice Hash a leaf node.
    /// @param data, raw data of the leaf.
    function _hashLeaf(bytes memory data) internal pure returns (bytes32) {
        return CryptographyLib.hash(abi.encodePacked(bytes1(0x00), data));
    }

    /// @notice Hash a node, which is not a leaf.
    /// @param left, left child hash.
    /// @param right, right child hash.
    function _hashNode(bytes32 left, bytes32 right) internal pure returns (bytes32) {
        return CryptographyLib.hash(abi.encodePacked(bytes1(0x01), left, right));
    }

    /// @notice Verify if element (key, data) exists in Merkle tree, given data, proof, and root.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param data: The data of the leaf to verify
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    /// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
    function verify(
        bytes32 root,
        bytes memory data,
        BinaryMerkleProof memory proof,
        uint256 key,
        uint256 numLeaves
    ) internal pure returns (bool) {
        // Check key is in tree
        if (key >= numLeaves) {
            return false;
        }

        // A sibling at height 1 is created by getting the hash of the data to prove.
        bytes32 hash = _hashLeaf(data);

        // Null proof is only valid if numLeaves = 1
        // If so, just verify hash(data) is root
        if (proof.sideNodes.length == 0) {
            if (numLeaves == 1) {
                return (root == hash);
            } else {
                return false;
            }
        }

        uint256 height = 1;
        uint256 stableEnd = key;

        // While the current subtree (of height 'height') is complete, determine
        // the position of the next sibling using the complete subtree algorithm.
        // 'stableEnd' tells us the ending index of the last full subtree. It gets
        // initialized to 'key' because the first full subtree was the
        // subtree of height 1, created above (and had an ending index of
        // 'key').

        while (true) {
            // Determine if the subtree is complete. This is accomplished by
            // rounding down the key to the nearest 1 << 'height', adding 1
            // << 'height', and comparing the result to the number of leaves in the
            // Merkle tree.

            uint256 subTreeStartIndex = (key / (1 << height)) * (1 << height);
            uint256 subTreeEndIndex = subTreeStartIndex + (1 << height) - 1;

            // If the Merkle tree does not have a leaf at index
            // 'subTreeEndIndex', then the subtree of the current height is not
            // a complete subtree.
            if (subTreeEndIndex >= numLeaves) {
                break;
            }
            stableEnd = subTreeEndIndex;

            // Determine if the key is in the first or the second half of
            // the subtree.
            if (proof.sideNodes.length <= height - 1) {
                return false;
            }
            if (key - subTreeStartIndex < (1 << (height - 1))) {
                hash = _hashNode(hash, proof.sideNodes[height - 1]);
            } else {
                hash = _hashNode(proof.sideNodes[height - 1], hash);
            }

            height += 1;
        }

        // Determine if the next hash belongs to an orphan that was elevated. This
        // is the case IFF 'stableEnd' (the last index of the largest full subtree)
        // is equal to the number of leaves in the Merkle tree.
        if (stableEnd != numLeaves - 1) {
            if (proof.sideNodes.length <= height - 1) {
                return false;
            }
            hash = _hashNode(hash, proof.sideNodes[height - 1]);
            height += 1;
        }

        // All remaining elements in the proof set will belong to a left sibling\
        // i.e proof sideNodes are hashed in "from the left"
        while (height - 1 < proof.sideNodes.length) {
            hash = _hashNode(proof.sideNodes[height - 1], hash);
            height += 1;
        }

        return (hash == root);
    }

    /// @notice Computes Merkle tree root from leaves.
    /// @param data, list of leaves' data in ascending for leaves order.
    function computeRoot(bytes[] memory data) internal pure returns (bytes32) {
        bytes32[] memory nodes = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            nodes[i] = _hashLeaf(data[i]);
        }
        uint256 size = (nodes.length + 1) >> 1;
        uint256 odd = nodes.length & 1;
        // pNodes are nodes in previous level.
        // We use pNodes to avoid damaging the input leaves.
        bytes32[] memory pNodes = nodes;
        while (true) {
            uint256 i = 0;
            for (; i < size - odd; ++i) {
                uint256 j = i << 1;
                nodes[i] = _hashNode(pNodes[j], pNodes[j + 1]);
            }
            if (odd == 1) {
                nodes[i] = pNodes[i << 1];
            }
            if (size == 1) {
                break;
            }
            odd = (size & 1);
            size = (size + 1) >> 1;
            pNodes = nodes;
        }
        return nodes[0];
    }

    /// @notice Appends a new element by calculating new root, returns new root and if successful, pure function.
    /// @param numLeaves, number of leaves in the tree currently.
    /// @param data, The data of the leaf to append.
    /// @param proof, Binary Merkle Proof to use for the leaf.
    function append(
        uint256 numLeaves,
        bytes memory data,
        BinaryMerkleProof memory proof
    ) internal pure returns (bytes32, bool) {
        bytes32 hash = _hashLeaf(data);

        // Since appended leaf is last leaf in tree by definition, its path consists only of set bits
        // (because all side nodes will be on its left)
        // Therefore, the number of steps in the proof = number of bits set in the key
        // E.g. If appending the 7th leaf, key = 0b110 => proofLength = 2.
        uint256 proofLength = 0;
        while (numLeaves > 0) {
            proofLength += numLeaves & 1;
            numLeaves = numLeaves >> 1;
        }

        if (proof.sideNodes.length != proofLength) {
            return (bytes32(0), false);
        }

        for (uint256 i = 0; i < proofLength; ++i) {
            hash = _hashNode(proof.sideNodes[i], hash);
        }

        return (hash, true);
    }

    /// @notice Adds a branch to the in-storage sparse representation of tree
    /// @dev We store the minimum subset of nodes necessary to calculate the root
    /// @param key: The key of the leaf
    /// @param data : The data of the leaf
    /// @param proof: The proof (assumed valid) of the leaf up to the root
    /// @param numLeaves: The total number of leaves in the tree
    /// @return : Success
    function addBranch(
        MerkleTree storage merkleTree,
        uint256 key,
        bytes memory data,
        BinaryMerkleProof memory proof,
        uint256 numLeaves
    ) internal returns (bool) {
        // Check key is in tree
        if (key >= numLeaves) {
            return false;
        }

        // A sibling at height 1 is created by getting the hash of the data to prove.
        bytes32 hash = _hashLeaf(data);

        // Add leaf and node for the data (Leaf just holds useful metadata for future `update`)
        merkleTree.leaves[key] = Leaf({height: proof.sideNodes.length, leafHash: hash});
        merkleTree.nodes[hash] = Node(Constants.EMPTY, Constants.EMPTY, Constants.EMPTY);

        // Null proof is only valid if numLeaves = 1
        if (proof.sideNodes.length == 0) {
            if (numLeaves == 1) {
                setRoot(merkleTree, hash); // setRoot not strictly needed in addBranch but useful for testing
                return true;
            } else {
                return false;
            }
        }

        // Variable to hold sibling hash at each proof step
        bytes32 siblingHash;

        // Create nodes for each element of the proof IFF they are 'new'
        // (i.e., not populated by earlier addBranch)
        for (uint256 j = 0; j < proof.sideNodes.length - 1; j++) {
            if (
                merkleTree.nodes[proof.sideNodes[j]].right == bytes32(0) &&
                merkleTree.nodes[proof.sideNodes[j]].left == bytes32(0)
            ) {
                merkleTree.nodes[proof.sideNodes[j]] = Node(
                    Constants.EMPTY,
                    Constants.EMPTY,
                    Constants.EMPTY
                );
            }
        }

        uint256 height = 1;
        uint256 stableEnd = key;

        while (true) {
            uint256 subTreeStartIndex = (key / (1 << height)) * (1 << height);
            uint256 subTreeEndIndex = subTreeStartIndex + (1 << height) - 1;

            if (subTreeEndIndex >= numLeaves) {
                break;
            }
            stableEnd = subTreeEndIndex;

            if (proof.sideNodes.length <= height - 1) {
                return false;
            }
            siblingHash = hash;
            if (key - subTreeStartIndex < (1 << (height - 1))) {
                hash = _safeHashNode(merkleTree, siblingHash, proof.sideNodes[height - 1]);
                merkleTree.nodes[hash] = Node(
                    siblingHash,
                    proof.sideNodes[height - 1],
                    Constants.EMPTY
                );
                merkleTree.nodes[siblingHash].parent = hash;
                merkleTree.nodes[proof.sideNodes[height - 1]].parent = hash;
            } else {
                hash = _safeHashNode(merkleTree, proof.sideNodes[height - 1], siblingHash);
                merkleTree.nodes[hash] = Node(
                    proof.sideNodes[height - 1],
                    siblingHash,
                    Constants.EMPTY
                );
                merkleTree.nodes[siblingHash].parent = hash;
                merkleTree.nodes[proof.sideNodes[height - 1]].parent = hash;
            }

            height += 1;
        }

        if (stableEnd != numLeaves - 1) {
            if (proof.sideNodes.length <= height - 1) {
                return false;
            }
            siblingHash = hash;
            hash = _safeHashNode(merkleTree, siblingHash, proof.sideNodes[height - 1]);
            merkleTree.nodes[hash] = Node(
                siblingHash,
                proof.sideNodes[height - 1],
                Constants.EMPTY
            );
            merkleTree.nodes[siblingHash].parent = hash;
            merkleTree.nodes[proof.sideNodes[height - 1]].parent = hash;
            height += 1;
        }

        while (height - 1 < proof.sideNodes.length) {
            siblingHash = hash;
            hash = _safeHashNode(merkleTree, proof.sideNodes[height - 1], siblingHash);
            merkleTree.nodes[hash] = Node(
                proof.sideNodes[height - 1],
                siblingHash,
                Constants.EMPTY
            );
            merkleTree.nodes[siblingHash].parent = hash;
            merkleTree.nodes[proof.sideNodes[height - 1]].parent = hash;
            height += 1;
        }

        // setRoot not strictly needed in addBranch but useful for testing
        setRoot(merkleTree, hash);
        return true;
    }

    // Dev function to check that no hash is overwritten with a different value
    // This should never happen if proofs are valid, but just in case...
    // (and we'll definitely want something like this when working in memory)
    function _safeHashNode(
        MerkleTree storage merkleTree,
        bytes32 left,
        bytes32 right
    ) internal view returns (bytes32) {
        bytes32 hash = _hashNode(left, right);
        Node memory node = merkleTree.nodes[hash];
        if (
            (node.left != bytes32(0) && node.left != Constants.EMPTY && node.left != left) ||
            (node.right != bytes32(0) && node.right != Constants.EMPTY && node.right != right)
        ) {
            revert("bad overwrite");
        }
        return hash;
    }

    /// @notice Update a given leaf
    /// @param key: The key of the leaf to be added
    /// @param data: The data to update the leaf with
    function update(
        MerkleTree storage merkleTree,
        uint256 key,
        bytes memory data
    ) internal returns (bytes32 root) {
        bytes32 parentHash;

        // Fetch the hash of the old leaf and its parent
        bytes32 oldHash = merkleTree.leaves[key].leafHash;
        bytes32 oldParentHash = merkleTree.nodes[oldHash].parent;

        // Create new leaf with new data and old parent
        bytes32 currentHash = _hashLeaf(data);
        merkleTree.nodes[currentHash] = Node(Constants.EMPTY, Constants.EMPTY, oldParentHash);

        // While not at the root :
        while (oldParentHash != Constants.EMPTY) {
            // Get node of 'old' parent
            Node memory oldParent = merkleTree.nodes[oldParentHash];

            // Hash new data with sibling to get new parent hash, and create parent node
            if (oldParent.left == oldHash) {
                parentHash = _hashNode(currentHash, oldParent.right);
                merkleTree.nodes[parentHash] = Node(currentHash, oldParent.right, oldParent.parent);
                merkleTree.nodes[currentHash].parent = parentHash;
                merkleTree.nodes[oldParent.right].parent = parentHash;
            } else {
                parentHash = _hashNode(oldParent.left, currentHash);
                merkleTree.nodes[parentHash] = Node(oldParent.left, currentHash, oldParent.parent);
                merkleTree.nodes[currentHash].parent = parentHash;
                merkleTree.nodes[oldParent.left].parent = parentHash;
            }

            // Step up the tree to the next 'old' parent
            oldHash = oldParentHash;
            oldParentHash = oldParent.parent;
            currentHash = parentHash;
        }
        root = currentHash;
        setRoot(merkleTree, root);
    }
}
