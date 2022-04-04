// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

/// @notice This library abstracts the hashing function used for the merkle tree implementation
library CryptographyLib {
    /// @notice The hash method
    /// @param data The bytes input data.
    /// @return The returned hash result.
    function hash(bytes memory data) internal pure returns (bytes32) {
        return sha256(data);
    }
}
