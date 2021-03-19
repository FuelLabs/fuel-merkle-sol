// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/// @notice Address utilites, namely martial from bytes32 to address.
library Address {

    /////////////
    // Methods //
    /////////////

    /// @notice This will martial a bytes32 down to an address.
    /// @param input The bytes32 data.
    /// @return addr The returned address.
    function fromBytes32(bytes32 input) internal pure returns (address addr) {
        return address(uint256(input));
    }
}