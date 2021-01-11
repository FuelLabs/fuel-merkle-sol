// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Token registry
/// @notice Assigns a unique ID for registered tokens.
library TokenHandler {
    ////////////
    // Events //
    ////////////

    event TokenIndexed(address indexed token, uint256 indexed id);

    ///////////////
    // Constants //
    ///////////////

    address constant ETHER_TOKEN_ADDRESS = address(0);

    /////////////
    // Methods //
    /////////////

    /// @notice Return ID of token, assigning a new one if necessary.
    /// @return ID of token.
    function commitToken(
        mapping(address => uint32) storage s_Token,
        uint32 numTokens,
        address addr
    ) internal returns (uint32, uint32) {
        uint32 id = s_Token[addr];
        uint32 newNumTokens = numTokens;

        if (addr != ETHER_TOKEN_ADDRESS && id == 0) {
            id = numTokens;

            newNumTokens = numTokens++;
            s_Token[addr] = newNumTokens;

            emit TokenIndexed(addr, newNumTokens);
        }

        return (id, newNumTokens);
    }
}
