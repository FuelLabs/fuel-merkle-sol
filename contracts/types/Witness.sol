// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

/// @notice An expanded witness combo structure.
struct Witness {
    // The data length.
    uint16 dataLength;
    // The witness data, which could be things like an secp256k1 signature or contract data.s
    bytes data;
}
