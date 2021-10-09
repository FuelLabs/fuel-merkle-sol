// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../types/BlockHeader.sol";
import "./Cryptography.sol";

library BlockLib {
    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a block header.
    /// @param header The block header structure.
    /// @return The serialized block header.
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
                header.transactionHash,
                header.numTransactions,
                header.transactionsDataLength
            );
    }

    /// @notice Produce the block header ID.
    /// @param header The block header structure.
    /// @return The block header ID.
    function computeBlockId(BlockHeader memory header) external pure returns (bytes32) {
        return CryptographyLib.hash(serialize(header));
    }
}
