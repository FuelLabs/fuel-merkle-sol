// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Block handler
library BlockHandler {
    ////////////////
    // Structures //
    ////////////////

    /// @notice Block header object
    struct BlockHeader {
        // Address of block proposer committing this rollup block
        address producer;
        // Previous rollup block's header hash
        bytes32 previousBlockHash;
        // Rollup block height
        uint32 height;
        // Ethereum block number when this rollup block is committed
        uint32 blockNumber;
        // Maximum token ID used in this rollup block
        uint32 maxTokenID;
        // Maximum address ID used in this rollup block
        uint32 maxAddressID;
        // Number of transaction roots
        uint16 rootsLength;
        // List of transaction roots. Each root is the Merkle root of a list of transactions.
        bytes32[] roots;
    }

    ////////////
    // Events //
    ////////////

    event BlockCommitted(
        address producer,
        uint32 numTokens,
        uint32 numAddresses,
        bytes32 indexed previousBlockHash,
        uint32 indexed height,
        bytes32[] roots
    );

    ///////////////
    // Constants //
    ///////////////

    uint256 constant TRANSACTION_ROOTS_MAX = 128;

    /////////////
    // Methods //
    /////////////

    /// @notice Commits a new rollup block.
    function commitBlock(
        mapping(uint256 => bytes32) storage s_BlockCommitments,
        uint32 minBlockNumber,
        bytes32 minBlockHash,
        uint32 height,
        bytes32[] calldata roots
    ) internal {}
}
