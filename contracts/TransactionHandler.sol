// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./types/TransactionLeaf.sol";
import "./types/TransactionProof.sol";

/// @title Transaction proof and leaf manipulation
library TransactionHandler {
    ///////////////
    // Constants //
    ///////////////

    // Minimum transaction size in bytes
    uint256 constant TRANSACTION_SIZE_MIN = 44;
    // Maximum transaction size in bytes
    uint256 constant TRANSACTION_SIZE_MAX = 896;
    // Maximum number of inputs per transaction
    uint8 constant INPUTS_MAX = 8;
    // Maximum number of outputs per transaction
    uint8 constant OUTPUTS_MAX = 8;
    // Empty leaf hash default value
    bytes32 constant EMPTY_LEAF_HASH = bytes32(0);

    /////////////
    // Methods //
    /////////////
}
