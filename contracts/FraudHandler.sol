// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Fraud proof handler
library FraudHandler {
    /// @dev Fraud finalization period. Mitigates miner frontrunning of fraud proofs.
    uint32 constant FRAUD_FINALIZATION_PERIOD = 10;

    /// @notice This will commit a fraud hash in storage.
    function commitFraudHash(
        mapping(address => mapping(bytes32 => uint32))
            storage s_FraudCommitments,
        bytes32 fraudHash
    ) internal {
        require(uint256(uint32(block.number)) == block.number);
        s_FraudCommitments[msg.sender][fraudHash] = uint32(block.number);
    }

    /// @notice Ensure that the calldata provided matches the fraud commitment hash.
    function requireValidFraudCommitment(
        mapping(address => mapping(bytes32 => uint32))
            storage s_FraudCommitments,
        bytes memory fraudData
    ) internal view {
        // Compute the fraud hash from input data.
        bytes32 fraudHash = keccak256(fraudData);

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
}
