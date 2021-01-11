// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Transaction metadata
struct Metadata {
    uint32 blockHeight;
    uint8 rootIndex;
    uint16 transactionIndex;
    uint8 outputIndex;
}

/// @notice Metadata helper functions
library MetadataHelper {
    ///////////////
    // Constants //
    ///////////////

    // Size of metadata object in bytes
    uint8 constant METADATA_SIZE = 8;

    /////////////
    // Methods //
    /////////////

    /// @notice Try to parse metadata bytes.
    function parseMetadata(bytes calldata s)
        internal
        pure
        returns (
            Metadata memory,
            uint256,
            bool
        )
    {
        // TODO
    }
}
