// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Root handler
/// @notice Roots represent a commitment to a list of transactions.
library RootHandler {
    ////////////
    // Events //
    ////////////

    event RootCommitted(
        bytes32 indexed root,
        address rootProducer,
        uint256 feeToken,
        uint256 fee,
        uint256 rootLength,
        bytes32 indexed merkleTreeRoot,
        bytes32 indexed commitmentHash
    );

    ///////////////
    // Constants //
    ///////////////

    // Maximum size of list of transactions, in bytes
    uint256 constant MAX_ROOT_SIZE = 32000;
    // Maximum number of transactions in list of transactions
    uint256 constant MAX_TRANSACTIONS_IN_ROOT = 2048;
}
