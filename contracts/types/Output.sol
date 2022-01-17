// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./DigestPointer.sol";

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
    ContractCreated,
    // A placeholder for checking invalid types
    END
}

/// @notice An expanded output combo structure: Coin, Variable, ContractCreate
/// @dev We use the same struct for compressed and uncompressed outputs, with properties as necessary
struct Output {
    // Type of output.
    OutputKind kind;
    // Full receiving address or script hash.
    bytes32 to;
    // Pointer to receiving address (compressed)
    DigestPointer toPointer;
    // Full asset_id identifier address.
    bytes32 asset_id;
    // asset_id index pointer (compressed)
    DigestPointer assetIDPointer;
    // Amount of coins to send.
    uint64 amount;
    // Contract only
    // Index of input contract.
    uint8 inputIndex;
    // Balance root of the Merkle Sum Tree.
    bytes32 balanceRoot;
    // OutputContract: State root of contract after transaction execution.
    bytes32 stateRoot;
    // Full contract id.
    bytes32 contractID;
    // Contract ID pointer (compressed)
    DigestPointer contractIDPointer;
}
