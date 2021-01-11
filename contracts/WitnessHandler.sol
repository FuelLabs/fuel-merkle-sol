// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Transaction witness registry
library WitnessHandler {
    ////////////
    // Events //
    ////////////

    event WitnessCommitted(
        address indexed owner,
        uint32 blockNumber,
        bytes32 indexed transactionId
    );

    /////////////
    // Methods //
    /////////////
}
