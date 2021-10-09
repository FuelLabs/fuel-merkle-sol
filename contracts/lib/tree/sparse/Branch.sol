// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "./Proofs.sol";

struct MerkleBranch {
    SparseCompactMerkleProof proof;
    bytes32 key;
    bytes value;
}
