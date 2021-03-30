// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice BlockCommitment structure.
struct BlockCommitment {
    // The direct children to this block. Only at most one can be finalized.
    bytes32[] children;
    // Default: is zero, for less storage use. This is whether the block is valid.
    bool isInvalid;
}
