// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
import "./Proofs.sol";

struct MerkleBranch {
    SparseCompactMerkleProof proof;
    bytes32 key;
    bytes value;
}
