// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

/// @notice This will point to a specific UTXO in a block.
struct TXOPointer {
    // The block height of the UTXO.
    uint32 blockHeight;
    // The transaction index.
    uint16 txIndex;
    // The output index.
    uint8 outputIndex;
}
