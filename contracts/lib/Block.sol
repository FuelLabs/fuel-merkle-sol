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
        // Abi-encode in two steps to avoid stack too deep
        bytes memory data =
            abi.encodePacked(
                header.producer,
                header.previousBlockRoot,
                header.height,
                header.blockNumber,
                header.digestRoot
            );

        return
            abi.encodePacked(
                data,
                header.digestHash,
                header.digestLength,
                header.transactionRoot,
                header.transactionSum,
                header.transactionHash,
                header.numTransactions,
                header.transactionsDataLength,
                header.validatorSetHash,
                header.requiredStake,
                header.withdrawalsRoot
            );
    }

    /// @notice Produce the block header ID.
    /// @param header The block header structure.
    /// @return The block header ID.
    function computeBlockId(BlockHeader memory header) external pure returns (bytes32) {
        return CryptographyLib.hash(serialize(header));
    }
}
