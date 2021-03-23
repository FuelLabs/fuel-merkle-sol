//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

/// @notice This is the Fuel protocol cryptography library.
library CryptographyLib {
    /////////////
    // Methods //
    /////////////

    /// @notice The primary hash method for Fuel.
    /// @param data The bytes input data.
    /// @return result The returned hash result.
    function hash(bytes memory data) internal pure returns (bytes32 result) {
        return sha256(data);
    }
}