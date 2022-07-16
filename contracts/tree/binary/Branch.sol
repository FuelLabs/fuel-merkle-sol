// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

struct MerkleBranch {
    bytes32[] proof;
    bytes32 key;
    bytes value;
}
