// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./TXOPointer.sol";

/// @notice The input kinds.
enum InputKind {
    // Simple coin input.
    Coin,
    // Complex contract input.
    Contract,
    // A placeholder for checking invalid types
    END
}

/// @notice An expanded input combo structure: InputCoin and InputContract
/// @dev We use the same struct for compressed and uncompressed inputs, with properties as necessary
struct Input {
    InputKind kind;
    // UTXO pointer (compressed)
    TXOPointer pointer;
    // Full UTXO ID.
    bytes32 utxoID;
    // Owner address.
    bytes32 owner;
    // Input amount.
    uint64 amount;
    // The token asset_id.
    bytes32 asset_id;
    // Index of witness that authorizes spending the coin.
    uint8 witnessIndex;
    // UTXO being spent must have been created at least this many blocks ago.
    uint64 maturity;
    // Predicate length.
    uint16 predicateLength;
    // Predicate data length.
    uint16 predicateDataLength;
    // Predicate bytecode.
    bytes predicate;
    // Predicate input data (parameters).
    bytes predicateData;
    // ContractOnly
    // This is the Merkle Sum Tree root for this contract.
    bytes32 balanceRoot;
    // This is the Sparse Merkle Tree state root for this contract.
    bytes32 stateRoot;
    // Contract ID
    bytes32 contractID;
}
