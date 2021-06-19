// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/SumMerkleTree.sol";
import "../types/MerkleTree.sol";

/// @title Mock for sum Merkle tree.
contract MockSumMerkleTree {
    using MerkleSumTree for MerkleTree;

    MerkleTree public merkleTree;

    /// @notice Verify if element (key, data) exists in Merkle tree, goes through side nodes and calculates hashes up to the root, compares roots.
    function verify(
        bytes32 root,
        uint256 rootSum,
        bytes memory data,
        uint256 sum,
        SumMerkleProof memory proof,
        uint256 key,
        uint256 numLeaves
    ) external pure returns (bool) {
        return MerkleSumTree.verify(root, rootSum, data, sum, proof, key, numLeaves);
    }

    /// @notice Computes sum Merkle tree root from leaves.
    function computeRoot(bytes[] memory data, uint256[] memory values)
        external
        pure
        returns (bytes32, uint256)
    {
        return MerkleSumTree.computeRoot(data, values);
    }
}
