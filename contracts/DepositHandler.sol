// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./FunnelFactory.sol";
import "./TokenHandler.sol";

/// @title Deposit handler
/// @notice Uniquely indexes an on-chain ETH or token deposit.
library DepositHandler {
    ////////////
    // Events //
    ////////////

    event DepositMade(
        address indexed account,
        address indexed token,
        uint256 amount
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Handle token deposit.
    /// @return Number of tokens.
    function deposit(
        mapping(address => mapping(uint32 => mapping(uint32 => uint256)))
            storage s_Deposit,
        mapping(address => uint32) storage s_Token,
        uint32 numTokens,
        address owner,
        address token
    ) internal returns (uint32) {
        // Get token ID (0 for ETH).
        // If token has not yet been deposited, a new token ID will be assigned.
        (uint32 tokenID, uint32 newNumTokens) =
            TokenHandler.commitToken(s_Token, numTokens, token);

        // TODO
        // Build create2 deposit funnel contract
        // let funnel := createFunnel(owner)

        // Variables
        uint256 amount = 0;

        if (token == TokenHandler.ETHER_TOKEN_ADDRESS) {
            // If ETH
            // amount = funnel.balance();
            // require(amount > 0, "value-underflow");
            // require(funnel.call(), "value-funnel");
            // require(funnel.balance() == 0, "value-check");
        } else {
            // If ERC-20
        }

        // Load current balance from storage
        // Deposits are uniquely identified by owner, token, and Ethereum bloc numbers, so a second deposit in the same block will simply update a single deposit object
        require(uint256(uint32(block.number)) == block.number);
        uint256 balanceAmount = s_Deposit[owner][tokenID][uint32(block.number)];
        s_Deposit[owner][tokenID][uint32(block.number)] =
            balanceAmount +
            amount;

        emit DepositMade(owner, token, amount);

        return newNumTokens;
    }
}
