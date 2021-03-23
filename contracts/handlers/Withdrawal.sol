// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../types/BlockHeader.sol";
import "../types/BlockCommitment.sol";
import "../provers/BlockHeader.sol";

/// @title Withdrawal handler.
library WithdrawalHandler {
    ////////////
    // Events //
    ////////////

    event WithdrawalMade(
        address indexed owner,
        address token,
        uint256 amount,
        uint32 indexed blockHeight,
        bytes32 indexed transactionId,
        uint8 outputIndex,
        uint16 transactionIndex
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Check if the withdrawal has already need processed.
    /// @param s_Withdrawals The withdrawal state.
    /// @param blockHeight The Fuel block height.
    /// @param withdrawalId The withdrawal ID hash.
    /// @return If the withdrawal has already been processed.
    function isWithdrawalProcessed(
        mapping(uint32 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint32 blockHeight,
        bytes32 withdrawalId
    ) internal view returns (bool) {
        return s_Withdrawals[blockHeight][withdrawalId];
    }

    /// @notice Withdraw a block producer bond from a finalizable block.
    /// @param s_Withdrawals The withdrawal state.
    /// @param bondSize The total bond size.
    /// @param blockHeader The Fuel block header.
    function bondWithdraw(
        mapping(uint32 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint256 bondSize,
        BlockHeader calldata blockHeader
    ) internal {
        // Setup block producer withdrawal ID (i.e. zero).
        bytes32 withdrawalId = bytes32(0);

        // Setup block height.
        uint32 blockHeight = blockHeader.height;

        // Caller must be block producer.
        require(blockHeader.producer == msg.sender, "caller-producer");

        // Block bond withdrawal must not have been processed yet.
        require(
            isWithdrawalProcessed(s_Withdrawals, blockHeight, withdrawalId) == false,
            "already-withdrawn"
        );

        // Set withdrawal as processed.
        s_Withdrawals[blockHeight][withdrawalId] = true;

        // Transfer bond back to block producer.
        payable(blockHeader.producer).transfer(bondSize);

        // Emit a WithdrawalMade event.
        emit WithdrawalMade(
            blockHeader.producer,
            address(0),
            bondSize,
            blockHeight,
            bytes32(0),
            0,
            0
        );
    }
}
