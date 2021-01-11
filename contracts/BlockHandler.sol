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
        // Maximum token ID used in this rollup block + 1
        uint32 numTokens;
        // Maximum address ID used in this rollup block + 1
        uint32 numAddresses;
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
        BlockHeader memory blockHeader,
        uint32 blockTip,
        uint256 bondSize,
        mapping(bytes32 => uint32) storage s_Roots,
        uint32 submissionDelay,
        uint32 penaltyUntil,
        bytes32[] calldata roots
    ) internal returns (uint32) {
        // Check that new rollup blocks builds on top of the tip
        require(blockHeader.height == blockTip + 1, "block-height");

        // Require at least one root submission
        require(roots.length > 0, "roots-length-underflow");

        // Require at most the maximum number of root submissions
        require(roots.length <= TRANSACTION_ROOTS_MAX, "roots-length-overflow");

        // Require value be bond size
        require(msg.value == bondSize);

        // Clear submitted roots from storage
        for (uint256 rootIndex = 0; rootIndex < roots.length; rootIndex++) {
            bytes32 rootHash = roots[rootIndex];
            uint32 rootBlockNumber = s_Roots[rootHash];

            // Check root exists
            require(rootBlockNumber != 0, "root-existance");

            // Check whether block producer has the right to use the root
            // In penalty mode (second condition is true), anyone can commit a block with roots without delay
            // In normal mode (second condition is false), only the operator can commit a block before waiting the root delay
            if (
                block.number < rootBlockNumber + submissionDelay &&
                block.number > penaltyUntil
            ) {
                require(msg.sender == blockHeader.producer, "caller-producer");
            }

            // Clear root from storage.
            delete s_Roots[rootHash];
        }

        emit BlockCommitted(
            blockHeader.producer,
            blockHeader.numTokens,
            blockHeader.numAddresses,
            blockHeader.previousBlockHash,
            blockHeader.height,
            blockHeader.roots
        );

        // Return new rollup block height as the tip
        return blockHeader.height;
    }
}
