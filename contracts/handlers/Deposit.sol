// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../vendor/openzeppelin/SafeCast.sol";

/// @title This handles the Fuel deposit logic.
/// @notice Uniquely indexes an on-chain ETH or token deposit.
/// @dev We allow the user to specify the amount, this way you can approve infinite if need be.
library DepositHandler {
    ////////////
    // Events //
    ////////////

    event DepositMade(
        uint32 blockNumber,
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 depositNonce
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Handle token deposit.
    /// @param account the owner (receiver / beneficiary) of the funds in Fuel.
    /// @param sender the sender of the funds from Ethereum.
    /// @param amount the amount to deposit to the owner.
    /// @param token the ERC20 token address of this deposit.
    /// @dev Deposits of ETH are not supported, instead use e.g. WETH.
    function deposit(
        address account,
        address sender,
        uint256 amount,
        address token,
        uint256 s_depositNonce
    ) internal {
        // Safely down-cast the current uint256 Ethereum block number to a uint32.
        uint32 blockNumber = SafeCast.toUint32(block.number);

        require(IERC20(token).transferFrom(sender, address(this), amount), "deposit-transfer");

        // Deposit made.
        emit DepositMade(blockNumber, account, address(token), amount, s_depositNonce);

        // Increment deposit nonce
        s_depositNonce += 1;
    }
}
