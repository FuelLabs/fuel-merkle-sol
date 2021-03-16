// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @title The Transaction Handler for Fuel.
library TransactionHandler {
    /// @dev Minimum transaction size in bytes.
    uint256 constant TRANSACTION_SIZE_MIN = 44;

    /// @dev Maximum transaction size in bytes.
    uint256 constant TRANSACTION_SIZE_MAX = 21000;

    /// @dev Maximum number of inputs per transaction.
    uint8 constant INPUTS_MAX = 16;

    /// @dev Maximum number of outputs per transaction.
    uint8 constant OUTPUTS_MAX = 16;

    /// @dev Empty leaf hash default value.
    bytes32 constant EMPTY_LEAF_HASH = bytes32(0);
}