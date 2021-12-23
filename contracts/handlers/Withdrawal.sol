// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../types/BlockHeader.sol";

/// @title Withdrawal handler.
library WithdrawalHandler {
    ////////////
    // Events //
    ////////////

    event WithdrawalMade(
        address indexed owner,
        address receiver,
        address indexed token,
        uint256 indexed amount
    );

    /////////////
    // Methods //
    /////////////

    function withdraw(
        address owner,
        address receiver,
        uint256 amount,
        address token,
        mapping(address => mapping(address => uint256)) storage s_withdrawals
    ) internal {
        require(s_withdrawals[owner][token] >= amount, "insufficient-balance");

        s_withdrawals[owner][token] -= amount;

        require(IERC20(token).transfer(receiver, amount), "withdraw-transfer");
        emit WithdrawalMade(owner, receiver, token, amount);
    }
}
