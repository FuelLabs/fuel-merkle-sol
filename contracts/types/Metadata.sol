// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

enum MetadataType {Metadata, MetadataDeposit}

/// @notice Transaction metadata. Points to an exact entry in the ledger or a deposit.
struct Metadata {
    MetadataType t;
    //////////////
    // Metadata //
    //////////////
    uint32 blockHeight;
    uint8 rootIndex;
    uint16 transactionIndex;
    uint8 outputIndex;
    /////////////////////
    // MetadataDeposit //
    /////////////////////
    uint32 tokenId;
    uint32 blockNumber;
}

/// @notice Metadata helper functions
library MetadataHelper {
    ///////////////
    // Constants //
    ///////////////

    // Size of metadata object in bytes
    uint8 constant METADATA_SIZE = 9;

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
        Metadata memory metadata;
        uint256 bytesUsed = METADATA_SIZE;

        if (s.length < bytesUsed) {
            return (metadata, bytesUsed, false);
        }

        // Type
        uint8 typeRaw = uint8(abi.decode(s[0:1], (bytes1)));
        if (typeRaw > uint8(MetadataType.MetadataDeposit))
            return (metadata, bytesUsed, false);
        metadata.t = MetadataType(typeRaw);

        // Metadata
        metadata.blockHeight = uint32(abi.decode(s[1:5], (bytes4)));
        metadata.rootIndex = uint8(abi.decode(s[5:6], (bytes1)));
        metadata.transactionIndex = uint16(abi.decode(s[6:8], (bytes2)));
        metadata.outputIndex = uint8(abi.decode(s[8:9], (bytes1)));

        // MetadataDeposit
        metadata.tokenId = uint32(abi.decode(s[1:5], (bytes4)));
        metadata.blockNumber = uint32(abi.decode(s[5:9], (bytes4)));

        return (metadata, bytesUsed, true);
    }
}
