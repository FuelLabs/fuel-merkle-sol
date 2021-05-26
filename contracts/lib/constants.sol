//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

library Constants {
    ///////////////
    // Constants //
    ///////////////

    /// @dev Maximum tree height
    uint256 internal constant MAX_HEIGHT = 256;

    /// @dev Empty node hash
    bytes32 internal constant EMPTY = sha256("");

    /// @dev Default value for sparse Merkle tree node
    bytes32 internal constant ZERO = bytes32(0);
}
