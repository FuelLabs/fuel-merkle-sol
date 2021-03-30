// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @dev The block commitment status.
enum BlockCommitmentStatus {
    // The block has not been committed.
    NotCommitted,

    // The block commitment is committed has been submitted and is valid.
    Committed,

    // The block commitment is in dispute.
    Disputed,

    // The block commitment is deemed invalid.
    Invalid
}

/// @notice BlockCommitment structure.
struct BlockCommitment {
    // The direct children to this block. Only at most one can be finalized.
    bytes32[] children;
    // The status of the block commitment.
    BlockCommitmentStatus status;
}
