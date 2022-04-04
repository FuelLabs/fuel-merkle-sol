// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

struct Node {
    bytes32 digest;
    bytes1 prefix;
    bytes32 leftChildPtr; // Zero if node is leaf
    bytes32 rightChildPtr; // Zero if node is leaf
    bytes32 key; // Zero if node is not leaf
    bytes leafData; // Zero if node is not leaf
}
