// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

/// @notice This will specify a digest registry pointer.
/// @dev Each block has a registry which will register a 32 byte chunk.
/// @dev This is used for compression of repeating 32 byte chunks.
struct DigestPointer {
    // The blockheight of the digest.
    uint32 blockHeight;
    // The index of the digest.
    uint16 index;
}
