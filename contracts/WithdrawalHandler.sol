// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./types/WithdrawalMetadata.sol";

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

    /// @notice Check if the withdrawal has already need processed.
    /// @return If the withdrawal has already been processed.
    function isWithdrawalProcessed(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint32 blockHeight,
        bytes32 withdrawalId
    ) internal view returns (bool) {
        return s_Withdrawals[blockHeight][withdrawalId];
    }

    /// @notice Do a withdrawal.
    function withdraw(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        bytes calldata transactionProof
    ) internal {
        // TODO
    }

    /// @notice Withdraw a block producer bond from a finalizable block.
    function bondWithdraw(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        bytes calldata blockHeader
    ) internal {
        // TODO
        // Setup block producer withdrawal ID (i.e. zero)
        bytes32 withdrawalId = bytes32(0);

        // Setup block height
    }
}
