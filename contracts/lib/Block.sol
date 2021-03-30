//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "../types/BlockHeader.sol";
import "./Cryptography.sol";

library BlockLib {
    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a block header.
    /// @param header The block header structure.
    /// @return The returned serialized block header.
    function serialize(BlockHeader memory header) internal pure returns (bytes memory) {
        // Encode packed.
        return
            abi.encodePacked(
                header.producer,
                header.previousBlockHash,
                header.height,
                header.blockNumber,
                header.digestRoot,
                header.digestHash,
                header.digestLength,
                header.transactionRoot,
                header.commitmentHash,
                header.transactionLength
            );
    }

    /// @notice Produce the Block header ID.
    /// @param header The block header structure.
    /// @return The returned block header hash.
    function computeBlockId(BlockHeader memory header) internal pure returns (bytes32) {
        return CryptographyLib.hash(serialize(header));
    }
}
