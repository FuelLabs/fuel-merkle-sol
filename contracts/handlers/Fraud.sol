// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../types/BlockCommitment.sol";

/// @title Fraud proof handler.
library FraudHandler {

    /////////////
    // Events //
    ////////////

    /// @dev General fraud committed error message.
    event FraudCommitted(bytes32 blockHash, string message);

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
}