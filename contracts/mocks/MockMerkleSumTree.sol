// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../tree/sum/SumMerkleTree.sol";

contract MockMerkleSumTree {
    bool public verified;
    bytes32 public root;
    uint256 public rootSum;

    function verify(
        bytes32 _root,
        uint256 _rootSum,
        bytes memory data,
        uint256 sum,
        SumMerkleProof memory proof,
        uint256 key,
        uint256 numLeaves
    ) public {
        bool result = MerkleSumTree.verify(_root, _rootSum, data, sum, proof, key, numLeaves);
        verified = result;
    }

    function computeRoot(bytes[] memory data, uint256[] memory values) public {
        (bytes32 resultRoot, uint256 resultSum) = MerkleSumTree.computeRoot(data, values);
        root = resultRoot;
        rootSum = resultSum;
    }
}
