// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Block handler
library BlockHandler {
    event BlockCommitted(
        address producer,
        uint256 numTokens,
        uint256 numAddresses,
        bytes32 indexed previousBlockHash,
        uint256 indexed height,
        bytes32[] roots
    );
}
