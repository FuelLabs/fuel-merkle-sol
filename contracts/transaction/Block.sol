//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "../types/BlockHeader.sol";

library BlockLib {

    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a block header.
    /// @param header The block header structure.
    /// @return data The returned serialized block header.
    function serialize(BlockHeader memory header) internal pure returns (bytes memory data) {
        // Encode packed.
        data = abi.encodePacked(
            header.producer,
            header.previousBlockHash,
            header.height,
            header.blockNumber,
            header.addressCommitmentHash,
            header.addressMerkleRoot,
            header.addressLength,
            header.merkleTreeRoot,
            header.commitmentHash,
            header.length
        );
    }
}