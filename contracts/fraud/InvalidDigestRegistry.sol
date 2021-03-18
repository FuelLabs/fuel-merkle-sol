// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../provers/BlockHeader.sol";
import "../utils/BinaryMerkleTree.sol";
import "../handlers/Fraud.sol";

/// @title This is a single round fraud proof for invalid block digest registry.
library InvalidDigestRegistry {

    /////////////
    // Methods //
    /////////////

    /// @notice Prove that a block registry is invalid.
    /// @dev We will compute the merkle tree root, then compare against the committed root.
    function proveInvalidRegistry(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        uint256 bondSize,
        address payable fraudCommitter,
        BlockHeader calldata blockHeader,
        bytes32[] calldata digests
    ) internal {
        // Ensure the block header is real.
        BlockHeaderProver.proveBlockHeader(
            s_BlockCommitments,
            finalizationDelay,
            blockHeader,
            BlockHeaderProver.AssertFinalized.Finalized
        );

        // Produce block hash.
        bytes32 blockHash = BlockLib.hash(blockHeader);

        // Require that the digests are provided correclty.
        require(
            sha256(abi.encodePacked(digests)) == blockHeader.digestCommitmentHash, 
            "invalid-commitment");

        // Compute root.
        if (blockHeader.digestMerkleRoot != BinaryMerkleTree.computeRoot(digests)) {
            // Revert this block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                blockHash
            );
        }
    }
}