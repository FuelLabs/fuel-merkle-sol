//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

library TransactionLib {
    ///////////////
    // Constants //
    ///////////////

    /// @dev Maximum transaction size in bytes.
    uint256 internal constant TRANSACTION_SIZE_MAX = 21000;

    /// @dev Empty leaf hash default value.
    bytes32 internal constant EMPTY_LEAF_HASH = bytes32(0);

    /// @dev Gas charged per byte of the transaction.
    uint64 internal constant GAS_PER_BYTE = 1;

    /// @dev Maximum gas per transaction.
    uint64 internal constant MAX_GAS_PER_TX = 100000;

    /// @dev Maximum number of inputs.
    uint64 internal constant MAX_INPUTS = 16;

    /// @dev Maximum number of outputs.
    uint64 internal constant MAX_OUTPUTS = 16;

    /// @dev Maximum length of predicate, in instructions.
    uint64 internal constant MAX_PREDICATE_LENGTH = 2400;

    /// @dev Maximum length of predicate data, in bytes.
    uint64 internal constant MAX_PREDICATE_DATA_LENGTH = 2400;

    /// @dev Maximum length of script, in instructions.
    uint64 internal constant MAX_SCRIPT_LENGTH = 2400;

    /// @dev Maximum length of script, in instructions.
    uint64 internal constant MAX_CONTRACT_LENGTH = 21000;

    /// @dev Maximum length of script data, in bytes.
    uint64 internal constant MAX_SCRIPT_DATA_LENGTH = 2400;

    /// @dev Maximum number of static contracts.
    uint64 internal constant MAX_STATIC_CONTRACTS = 256;

    /// @dev Max witnesses.
    uint64 internal constant MAX_WITNESSES = 16;
}
