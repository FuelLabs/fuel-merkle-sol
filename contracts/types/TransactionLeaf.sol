// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Leaf of transaction Merkle tree.
struct TransactionLeaf {
    // Length of leaf in bytes
    uint16 length;
    // List of metadata, one per input
    bytes8[] metadata;
    // List of witnesses
    bytes1[] witnesses;
    // List of inputs
    bytes1[] inputs;
    // List of outputs
    bytes1[] outputs;
}
