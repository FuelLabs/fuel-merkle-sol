// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../tree/binary/BinaryMerkleTree.sol";

contract MockBinaryMerkleTree {
    bool public verified;
    bytes32 public root;

    function verify(
        bytes32 _root,
        bytes memory data,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public returns (bool) {
        bool result = BinaryMerkleTree.verify(_root, data, proof, key, numLeaves);
        verified = result;
        return result;
    }

    function computeRoot(bytes[] memory data) public returns (bytes32) {
        bytes32 result = BinaryMerkleTree.computeRoot(data);
        root = result;
        return root;
    }

    function append(
        uint256 numLeaves,
        bytes memory data,
        bytes32[] memory proof
    ) public returns (bytes32, bool) {
        (root, verified) = BinaryMerkleTree.append(numLeaves, data, proof);
        return (root, verified);
    }

    function addBranchesAndUpdate(
        MerkleBranch[] memory branches,
        bytes32 _root,
        bytes32 key,
        bytes memory value,
        uint256 numLeaves
    ) public returns (bytes32) {
        root = BinaryMerkleTree.addBranchesAndUpdate(branches, _root, key, value, numLeaves);
        return root;
    }
}
