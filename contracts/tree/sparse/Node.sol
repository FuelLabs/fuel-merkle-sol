// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;

struct Node {
    bytes32 digest;
    bytes1 prefix;
    bytes32 leftChildPtr; // Zero if node is leaf
    bytes32 rightChildPtr; // Zero if node is leaf
    bytes32 key; // Zero if node is not leaf
    bytes leafData; // Zero if node is not leaf
}
