//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/tree/sparse/SparseMerkleTree.sol";

contract MockSparseMerkleTree {
    bool public verified;
    bytes32 public root;

    function verifyCompact(
        SparseCompactMerkleProof memory proof,
        bytes32 key,
        bytes memory value,
        bytes32 _root
    ) public {
        verified = SparseMerkleTree.verifyCompact(proof, key, value, _root);
    }

    function addBranchesAndUpdate(
        MerkleBranch[] memory branches,
        bytes32 _root,
        bytes32 key,
        bytes memory value
    ) public {
        root = SparseMerkleTree.addBranchesAndUpdate(branches, _root, key, value);
    }

    function addBranchesAndDelete(
        MerkleBranch[] memory branches,
        bytes32 _root,
        bytes32 key
    ) public {
        root = SparseMerkleTree.addBranchesAndDelete(branches, _root, key);
    }
}
