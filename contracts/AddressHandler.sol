// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Address registry
/// @notice Assigns a unique ID for registered addresses.
library AddressHandler {
    ////////////
    // Events //
    ////////////

    event AddressIndexed(address indexed owner, uint32 indexed id);

    /////////////
    // Methods //
    /////////////

    /// @notice Return ID of address, assigning a new one if necessary.
    /// @return ID of address.
    function commitAddress(
        mapping(address => uint32) storage s_Addresses,
        uint32 numAddresses,
        address addr
    ) internal returns (uint32) {
        uint32 id = s_Addresses[addr];
        uint32 newNumAddresses = numAddresses;

        if (id == 0) {
            id = numAddresses;

            newNumAddresses = numAddresses + 1;
            s_Addresses[addr] = newNumAddresses;

            emit AddressIndexed(addr, newNumAddresses);
        }

        return newNumAddresses;
    }
}
