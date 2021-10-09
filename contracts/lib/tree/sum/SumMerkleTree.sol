// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../lib/Cryptography.sol";
import "./SumMerkleProof.sol";
import "../Constants.sol";
import "../Utils.sol";
import "./TreeHasher.sol";

/// @title Sum Merkle Tree.
/// @notice spec can be found at https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/cryptographic_primitives.md#binary-merkle-sum-tree.
contract MerkleSumTree {
    using SafeMath for uint256;

    /// @notice Verify if element (key, data) exists in Merkle tree, decompacts proof, goes through side nodes and calculates hashes up to the root, compares roots.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    function verify(
        bytes32 root,
        uint256 rootSum,
        bytes memory data,
        uint256 _sum,
        SumMerkleProof memory proof,
        uint256 key,
        uint256 numLeaves
    ) external pure returns (bool) {
        // Check proof is correct length for the key it is proving
        if (numLeaves <= 1) {
            if (proof.sideNodes.length != 0) {
                return false;
            }
        } else if (proof.sideNodes.length != pathLengthFromKey(key, numLeaves)) {
            return false;
        }

        // Check key is in tree
        if (key >= numLeaves) {
            return false;
        }

        // Check proof has valid format
        if (proof.nodeSums.length != proof.sideNodes.length) {
            return false;
        }

        // A sibling at height 1 is created by getting the LeafSum of the original data.
        bytes32 digest = hashLeaf(_sum, data);
        uint256 sum = _sum;

        // Handle case where proof is empty: i.e, only one leaf exists, so verify hash(data) is root
        if (proof.sideNodes.length == 0) {
            if (numLeaves == 1) {
                return (digest == root) && (sum == rootSum);
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
                digest = hashNode(
                    sum,
                    digest,
                    proof.nodeSums[height - 1],
                    proof.sideNodes[height - 1]
                );
            } else {
                digest = hashNode(
                    proof.nodeSums[height - 1],
                    proof.sideNodes[height - 1],
                    sum,
                    digest
                );
            }
            sum += proof.nodeSums[height - 1];

            height += 1;
        }

        // Determine if the next hash belongs to an orphan that was elevated. This
        // is the case IFF 'stableEnd' (the last index of the largest full subtree)
        // is equal to the number of leaves in the Merkle tree.
        if (stableEnd != numLeaves - 1) {
            if (proof.sideNodes.length <= height - 1) {
                return false;
            }
            digest = hashNode(sum, digest, proof.nodeSums[height - 1], proof.sideNodes[height - 1]);
            sum += proof.nodeSums[height - 1];
            height += 1;
        }

        // All remaining elements in the proof set will belong to a left sibling.
        while (height - 1 < proof.sideNodes.length) {
            digest = hashNode(proof.nodeSums[height - 1], proof.sideNodes[height - 1], sum, digest);
            sum += proof.nodeSums[height - 1];
            height += 1;
        }

        return (digest == root) && (sum == rootSum);
    }

    /// @notice Computes sparse Merkle tree root from leaves.
    /// @param data, list of leaves' data in ascending order of leaves.
    /// @param values, list of leaves' values in ascending order of leaves.
    function computeRoot(bytes[] memory data, uint256[] memory values)
        external
        pure
        returns (bytes32, uint256)
    {
        bytes32[] memory nodes = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            nodes[i] = hashLeaf(values[i], data[i]);
        }
        uint256 odd = nodes.length & 1;
        uint256 size = (nodes.length + 1) >> 1;
        uint256[] memory sums = new uint256[](size);
        // pNodes are nodes in previous level.
        // We use pNodes to avoid damaging the input leaves.
        bytes32[] memory pNodes = nodes;
        uint256[] memory pSums = values;
        while (true) {
            uint256 i = 0;
            for (; i < size - odd; ++i) {
                uint256 j = i << 1;
                nodes[i] = hashNode(pSums[j], pNodes[j], pSums[j + 1], pNodes[j + 1]);
                sums[i] = pSums[j].add(pSums[j + 1]);
            }
            if (odd == 1) {
                nodes[i] = pNodes[i << 1];
                sums[i] = pSums[i << 1];
            }
            if (size == 1) {
                break;
            }
            odd = (size & 1);
            size = (size + 1) >> 1;
            pNodes = nodes;
            pSums = sums;
        }
        return (nodes[0], sums[0]);
    }
}
