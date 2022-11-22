// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {Node} from "./Node.sol";
import {nodeDigest, leafDigest, hashNode} from "./TreeHasher.sol";
import {hashLeaf} from "./TreeHasher.sol";
import {MerkleBranch} from "./Branch.sol";
import {BinaryMerkleProof} from "./BinaryMerkleProof.sol";
import {Constants} from "../Constants.sol";
import {pathLengthFromKey, getStartingBit} from "../Utils.sol";
import {getBitAtFromMSB} from "../Utils.sol";
import {verifyBinaryTree, verifyBinaryTreeDigest} from "./BinaryMerkleTreeUtils.sol";
import {computeBinaryTreeRoot} from "./BinaryMerkleTreeUtils.sol";
import {getPtrToNode, getNodeAtPtr} from "./BinaryMerkleTreeUtils.sol";
import {addBranch, sideNodesForRoot} from "./BinaryMerkleTreeUtils.sol";

/// @title Binary Merkle Tree.
/// @notice spec can be found at https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/cryptographicprimitives.md#binary-merkle-tree.
library BinaryMerkleTree {
    /// @notice Verify if element (key, data) exists in Merkle tree, given data, proof, and root.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param data: The data of the leaf to verify
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    /// @return : Whether the proof is valid
    /// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
    function verify(
        bytes32 root,
        bytes memory data,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public pure returns (bool) {
        return verifyBinaryTree(root, data, proof, key, numLeaves);
    }

    /// @notice Verify if element (key, digest) exists in Merkle tree, given digest, proof, and root.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param digest: The digest of the data of the leaf to verify
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    /// @return : Whether the proof is valid
    /// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
    function verifyDigest(
        bytes32 root,
        bytes32 digest,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public pure returns (bool) {
        return verifyBinaryTreeDigest(root, digest, proof, key, numLeaves);
    }

    /// @notice Computes Merkle tree root from leaves.
    /// @param data: list of leaves' data in ascending for leaves order.
    /// @return : The root of the tree
    function computeRoot(bytes[] memory data) public pure returns (bytes32) {
        return computeBinaryTreeRoot(data);
    }

    /// @notice Appends a new element by calculating new root, returns new root and if successful, pure function.
    /// @param numLeaves, number of leaves in the tree currently.
    /// @param data, The data of the leaf to append.
    /// @param proof, Binary Merkle Proof to use for the leaf.
    /// @return : The root of the new tree
    /// @return : Whether the proof is valid
    function append(
        uint256 numLeaves,
        bytes memory data,
        bytes32[] memory proof
    ) public pure returns (bytes32, bool) {
        bytes32 digest = leafDigest(data);

        // Since appended leaf is last leaf in tree by definition, its path consists only of set bits
        // (because all side nodes will be on its left)
        // Therefore, the number of steps in the proof should equal number of bits set in the key
        // E.g. If appending the 7th leaf, key = 0b110 => proofLength = 2.

        uint256 proofLength = 0;
        while (numLeaves > 0) {
            proofLength += numLeaves & 1;
            numLeaves = numLeaves >> 1;
        }

        if (proof.length != proofLength) {
            return (Constants.NULL, false);
        }

        // If proof length is correctly 0, tree is empty, and we are appending the first leaf
        if (proofLength == 0) {
            digest = leafDigest(data);
        }
        // Otherwise tree non-empty so we calculate nodes up to root
        else {
            for (uint256 i = 0; i < proofLength; ++i) {
                digest = nodeDigest(proof[i], digest);
            }
        }

        return (digest, true);
    }

    /// @notice Update a given leaf
    /// @param key: The key of the leaf to be added
    /// @param value: The data to update the leaf with
    /// @param sideNodes: The sideNodes from the leaf to the root
    /// @param numLeaves: The total number of leaves in the tree
    /// @return currentPtr : The pointer to the root of the tree
    function updateWithSideNodes(
        bytes32 key,
        bytes memory value,
        bytes32[] memory sideNodes,
        uint256 numLeaves
    ) public pure returns (bytes32 currentPtr) {
        Node memory currentNode = hashLeaf(value);
        currentPtr = getPtrToNode(currentNode);

        // If numleaves <= 1, then the root is just the leaf hash (or ZERO)
        if (numLeaves > 1) {
            uint256 startingBit = getStartingBit(numLeaves);
            uint256 pathLength = pathLengthFromKey(uint256(key), numLeaves);

            for (uint256 i = 0; i < pathLength; i += 1) {
                if (getBitAtFromMSB(key, startingBit + pathLength - 1 - i) == 1) {
                    currentNode = hashNode(
                        sideNodes[i],
                        currentPtr,
                        getNodeAtPtr(sideNodes[i]).digest,
                        currentNode.digest
                    );
                } else {
                    currentNode = hashNode(
                        currentPtr,
                        sideNodes[i],
                        currentNode.digest,
                        getNodeAtPtr(sideNodes[i]).digest
                    );
                }

                currentPtr = getPtrToNode(currentNode);
            }
        }
    }

    /// @notice Add an array of branches and update one of them
    /// @param branches: The array of branches to add
    /// @param root: The root of the tree
    /// @param key: The key of the leaf to be added
    /// @param value: The data to update the leaf with
    /// @param numLeaves: The total number of leaves in the tree
    /// @return newRoot : The new root of the tree
    function addBranchesAndUpdate(
        MerkleBranch[] memory branches,
        bytes32 root,
        bytes32 key,
        bytes memory value,
        uint256 numLeaves
    ) public pure returns (bytes32 newRoot) {
        bytes32 rootPtr = Constants.ZERO;
        for (uint256 i = 0; i < branches.length; i++) {
            rootPtr = addBranch(
                branches[i].key,
                branches[i].value,
                branches[i].proof,
                root,
                rootPtr,
                numLeaves
            );
        }

        bytes32[] memory sideNodes = sideNodesForRoot(key, rootPtr, numLeaves);
        bytes32 newRootPtr = updateWithSideNodes(key, value, sideNodes, numLeaves);

        return getNodeAtPtr(newRootPtr).digest;
    }

    /// @notice Derive the proof for a new appended leaf from the proof for the last appended leaf
    /// @param oldProof: The proof to the last appeneded leaf
    /// @param lastLeaf: The last leaf hash
    /// @param key: The key of the new leaf
    /// @return : The proof for the appending of the new leaf
    /// @dev This function assumes that oldProof has been verified in position (key - 1)
    function deriveAppendProofFromLastProof(
        bytes32[] memory oldProof,
        bytes32 lastLeaf,
        uint256 key
    ) public pure returns (bytes32[] memory) {
        // First prepend last leaf to its proof.
        bytes32[] memory newProofBasis = new bytes32[](oldProof.length + 1);
        newProofBasis[0] = leafDigest(abi.encodePacked(lastLeaf));
        for (uint256 i = 0; i < oldProof.length; i += 1) {
            newProofBasis[i + 1] = oldProof[i];
        }

        // If the new leaf is "even", this will already be the new proof
        if (key & 1 == 1) {
            return newProofBasis;
        }

        // Otherwise, get the expected length of the new proof (it's the last leaf by definition, so numLeaves = key + 1)
        // Assuming old proof was valid, this will always be shorter than the old proof.
        uint256 expectedProofLength = pathLengthFromKey(key, key + 1);

        bytes32[] memory newProof = new bytes32[](expectedProofLength);

        // "Hash up" through old proof until we have the correct first sidenode
        bytes32 firstSideNode = newProofBasis[0];
        uint256 hashedUpIndex = 0;
        while (hashedUpIndex < (newProofBasis.length - expectedProofLength)) {
            firstSideNode = nodeDigest(newProofBasis[hashedUpIndex + 1], firstSideNode);
            hashedUpIndex += 1;
        }

        // Set the calculated first side node as the first element in the proof
        newProof[0] = firstSideNode;

        // Then append the remaining (unchanged) sidenodes, if any
        for (uint256 j = 1; j < expectedProofLength; j += 1) {
            newProof[j] = newProofBasis[hashedUpIndex + j];
        }

        return newProof;
    }
}
