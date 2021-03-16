// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

/// @notice This will specify an address pointer.
struct AddressPointer {
    // The block height of the referenced address.
    uint32 blockHeight;

    // The index of the address specified in this block.
    uint16 addressIndex;
}