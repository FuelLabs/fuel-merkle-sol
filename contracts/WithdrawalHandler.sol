// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Withdrawal handler
library WithdrawalHandler {
    ////////////
    // Events //
    ////////////

    event WithdrawalMade(
        address indexed account,
        address token,
        uint256 amount,
        uint32 indexed blockHeight,
        uint16 rootIndex,
        bytes32 indexed transactionLeafHash,
        uint8 outputIndex,
        bytes32 transactionId
    );

    /////////////
    // Methods //
    /////////////
}
