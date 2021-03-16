// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "./AddressPointer.sol";

/// @notice Output kind.
enum OutputKind {
    // Simple coin output.
    Coin,

    // Balance state and input index.
    Contract,

    // A withdrawal.
    Withdrawal,

    // Return change.
    Change,

    // A specified variable.
    Variable,

    // When a contract is created.
    ContractCreated
}

/// @notice An expanded output combo structure: Coin, Variable, ContractCreated.
struct Output {
    // Type of output.
    OutputKind kind;

    // Receiving address or script hash.
    AddressPointer toPointer;

    // Color index.
    AddressPointer colorIndex;

    // To address.
    bytes32 to;

    // Amount of coins to send.
    uint64 amount;

    // Expanded color identifier address.
    bytes32 color;

    // Index of input contract.
    uint8 inputIndex;

    // Balance root of the Merkle Sum Tree.
    bytes32 balanceRoot;

    // OutputContract: State root of contract after transaction execution.
    bytes32 stateRoot;

    // OutputContractCreated: contract id.
    bytes32 contractID;

    // This is additional metadata for decoding purposes.
    uint16 _bytesize;
}
