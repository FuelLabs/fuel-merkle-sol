// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "./TXOPointer.sol";
import "./DigestPointer.sol";

/// @notice The input kinds.
enum InputKind {
    // Simple coin input.
    Coin,

    // Complex contract input.
    Contract
}

/// @notice An expanded input combo structure: InputCoin and InputContract.
struct Input {
    InputKind kind;

    // UTXO ID.
    bytes32 utxoID;

    // UTXO pointer. 
    TXOPointer pointer;

    // Index of witness that authorizes spending the coin.
    uint8 witnessIndex;

    // This is the expanded owner address.
    bytes32 owner;

    // The pointer of the color.
    DigestPointer colorIndex;

    // The token color.
    bytes32 color;

    // This is the input amount.
    uint64 amount;

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

    // ContractOnly: contractID.
    bytes32 contractID;

    // This is the Merkle Sum Tree root for this contract.
    bytes32 balanceRoot;
    
    // This is the Sparse Merkle Tree state root for this contract.
    bytes32 stateRoot;

    // This is additional metadata for decoding purposes.
    uint16 _bytesize;
}
