// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Metadata of a withdrawal transcation in the rollup. Points to an entry in a block.
struct WithdrawalMetadata {
    // Index of root in list of roots
    uint16 rootIndex;
    // Hash of transaction leaf in tree rooted at rootIndex
    bytes32 transactionLeafHash;
    // Index of output in list of outputs of transaction in the transaction leaf
    uint8 outputIndex;
}
