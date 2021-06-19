//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

/// @notice This is the Fuel protocol cryptography library.
library CryptographyLib {
    /////////////
    // Methods //
    /////////////

    /// @notice The primary hash method for Fuel.
    /// @param data The bytes input data.
    /// @return The returned hash result.
    function hash(bytes memory data) internal pure returns (bytes32) {
        return sha256(data);
    }
}
