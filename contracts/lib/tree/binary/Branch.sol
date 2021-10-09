// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

struct MerkleBranch {
    bytes32[] proof;
    bytes32 key;
    bytes value;
}
