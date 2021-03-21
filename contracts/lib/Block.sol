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
            header.digestCommitmentHash,
            header.digestMerkleRoot,
            header.digestLength,
            header.merkleTreeRoot,
            header.commitmentHash,
            header.length
        );
    }

    /// @notice Produce the Block header ID.
    /// @param header The block header structure.
    /// @return blockHash The returned block header hash.
    function computeBlockId(BlockHeader memory header) internal pure returns (bytes32 blockHash) {
        return sha256(serialize(header));
    }
}
