// SPDX-License-Identifier: Apache-2.0
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

    event DepositMade(address indexed account, address indexed token, uint256 amount);

    /////////////
    // Methods //
    /////////////

    /// @notice Handle token deposit.
    /// @param s_Deposit the internal storage being changed by the logic.
    /// @param account the owner of the funds in Fuel.
    /// @param sender the sender of the funds in Fuel.
    /// @param amount the amount to deposit to the owner.
    /// @param token the ERC20 token address of this deposit.
    /// @dev Deposits of ETH are not supported, instead use e.g. WETH.
    function deposit(
        mapping(address => mapping(address => mapping(uint32 => uint256))) storage s_Deposit,
        address account,
        address sender,
        uint256 amount,
        IERC20 token
    ) internal {
        // Safely down-cast the current uint256 Ethereum block number to a uint32.
        uint32 blockNumber = SafeCast.toUint32(block.number);

        // Ensure the funds are transferred over.
        // TODO: ensure re-entrancy modelling is done and has no negative effects.
        require(token.transferFrom(sender, address(this), amount), "deposit-transfer");

        // Get the balance amount from state.
        uint256 balanceAmount = s_Deposit[account][address(token)][blockNumber];

        // Increase amount.
        s_Deposit[account][address(token)][blockNumber] = balanceAmount + amount;

        // Deposit made.
        emit DepositMade(account, address(token), amount);
    }
}
