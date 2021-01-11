// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @notice Transaction metadata. Points to an exact entry in the ledger or a deposit.
struct Metadata {
    // Metadata
    uint32 blockHeight;
    uint8 rootIndex;
    uint16 transactionIndex;
    uint8 outputIndex;
    // MetadataDeposit
    uint32 tokenId;
    uint32 blockNumber;
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
        // Since metadata doesn't have a type and is always METADATA_SIZE bytes, just parse both options
        Metadata memory metadata;
        uint256 bytesUsed = METADATA_SIZE;

        if (s.length < bytesUsed) {
            return (metadata, bytesUsed, false);
        }

        // Metadata
        metadata.blockHeight = uint32(abi.decode(s[0:4], (bytes4)));
        metadata.rootIndex = uint8(abi.decode(s[4:5], (bytes1)));
        metadata.transactionIndex = uint16(abi.decode(s[5:7], (bytes2)));
        metadata.outputIndex = uint8(abi.decode(s[7:8], (bytes1)));

        // MetadataDeposit
        metadata.tokenId = uint32(abi.decode(s[0:4], (bytes4)));
        metadata.blockNumber = uint32(abi.decode(s[4:8], (bytes4)));

        return (metadata, bytesUsed, true);
    }
}
