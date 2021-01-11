// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Transaction witness registry
library WitnessHandler {
    ////////////
    // Events //
    ////////////

    event WitnessCommitted(
        address indexed owner,
        uint32 blockNumber,
        bytes32 indexed transactionId
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Register a new Caller witness for a transaction ID.
    function commitWitness(
        mapping(address => mapping(uint32 => bytes32)) storage s_Witnesses,
        bytes32 id
    ) internal {
        require(uint256(uint32(block.number)) == block.number);

        // Witness must not already be registered
        require(
            s_Witnesses[msg.sender][uint32(block.number)] == 0,
            "already-witnessed"
        );

        // Store the transaction hash keyed by the caller and block number
        s_Witnesses[msg.sender][uint32(block.number)] = id;
    }
}
