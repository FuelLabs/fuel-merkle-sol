// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {BinaryMerkleTree, MerkleBranch} from "../tree/binary/BinaryMerkleTree.sol";

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

    function verifyDigest(
        bytes32 _root,
        bytes32 digest,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public pure returns (bool) {
        return BinaryMerkleTree.verifyDigest(_root, digest, proof, key, numLeaves);
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
