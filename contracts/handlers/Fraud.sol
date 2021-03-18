// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../types/BlockCommitment.sol";

/// @title Fraud proof handler.
library FraudHandler {

    ///////////////
    // Constants //
    ///////////////

    /// @dev Fraud finalization period. Mitigates miner frontrunning of fraud proofs.
    uint32 constant internal FRAUD_FINALIZATION_PERIOD = 10;

    /////////////
    // Methods //
    /////////////

    /// @notice This will commit a fraud hash in storage.
    /// @param s_FraudCommitments the state to be modified by this method.
    /// @param fraudHash the fraud hash of one-time fraud commitment.
    function commitFraudHash(
        mapping(address => mapping(bytes32 => uint32))
            storage s_FraudCommitments,
        bytes32 fraudHash
    ) internal {
        // Ensure block number downcasing is correct.
        require(uint256(uint32(block.number)) == block.number, "block-number");

        // Commit this fraud hash.
        s_FraudCommitments[msg.sender][fraudHash] = uint32(block.number);
    }

    /// @notice Ensure that the calldata provided matches the fraud commitment hash.
    /// @param s_FraudCommitments the state to be modified by this method.
    /// @param fraudData the fraud data to be checked against a specific commitment.
    function requireValidFraudCommitment(
        mapping(address => mapping(bytes32 => uint32))
            storage s_FraudCommitments,
        bytes memory fraudData
    ) internal view {
        // Compute the fraud hash from input data.
        bytes32 fraudHash = sha256(fraudData);

        // Get the fraud commitment block number from storage.
        uint32 commitmentBlockNumber =
            s_FraudCommitments[msg.sender][fraudHash];

        // Check the fraud commitment exists.
        require(commitmentBlockNumber != 0, "fraud-commitment");

        // Require that current block number >= commitment block number + period.
        require(
            block.number >= commitmentBlockNumber + FRAUD_FINALIZATION_PERIOD,
            "fraud-commitment-hash"
        );
    }

    /// @notice This will revert a block in the commitments.
    /// @param s_BlockCommitments the state to be modified by this method.
    /// @param blockHash the fraud hash of one-time fraud commitment.
    function revertBlock(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint256 bondSize,
        address payable fraudCommitter,
        bytes32 blockHash
    ) internal {
        // Set the block to invald.
        s_BlockCommitments[blockHash].isInvalid = true;

        // Bond size.
        fraudCommitter.transfer(bondSize);
    }
}