// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/// @title Root handler
/// @notice Roots represent a commitment to a list of transactions.
library RootHandler {
    ////////////////
    // Structures //
    ////////////////

    /// @notice Transaction root header object. Contains Merkle tree root and important metadata.
    struct RootHeader {
        // Address of root producer
        address producer;
        // Merkle root of list of transactions
        bytes32 merkleTreeRoot;
        // Simple hash of list of transactions
        bytes32 commitmentHash;
        // Length of list of transactions, in bytes
        uint32 length;
        // Token ID of all fees paid in this root
        uint32 feeToken;
        // Feerate of all fees paid in this root
        uint256 fee;
    }

    ////////////
    // Events //
    ////////////

    event RootCommitted(
        bytes32 indexed root,
        address rootProducer,
        uint32 feeToken,
        uint256 fee,
        uint32 rootLength,
        bytes32 indexed merkleTreeRoot,
        bytes32 indexed commitmentHash
    );

    ///////////////
    // Constants //
    ///////////////

    // Maximum size of list of transactions, in bytes
    uint32 constant MAX_ROOT_SIZE = 32000;
    // Maximum number of transactions in list of transactions
    uint32 constant MAX_TRANSACTIONS_IN_ROOT = 2048;

    /////////////
    // Methods //
    /////////////

    function commitRoot(
        mapping(bytes32 => uint32) storage s_Roots,
        uint32 numTokens,
        bytes32 merkleTreeRoot,
        uint32 token,
        uint256 fee,
        bytes calldata transactions
    ) internal {
        // TODO refactor to instead pass in an array of txs and bound by num of txs
        bytes memory packedTransactions = abi.encodePacked(transactions);
        bytes32 commitmentHash = keccak256(packedTransactions);

        // Calldata size must be at least as big as the minimum transaction size (44 bytes)
        require(packedTransactions.length >= 44, "root-size-overflow");
        // Calldata max size enforcement (~2M gas / 16 gas per byte/64kb payload target)
        require(
            packedTransactions.length <= uint256(MAX_ROOT_SIZE),
            "root-size-overflow"
        );
        // TODO this check can be removed?
        // require(lte(calldatasize(), add(MAX_ROOT_SIZE, mul32(6))), error"calldata-size-overflow")

        // Caller/msg.sender must not be a contract
        // TODO make sure this check is correct
        require(tx.origin == msg.sender, "origin-not-caller");
        uint256 callerCodeSize;
        assembly {
            callerCodeSize := extcodesize(caller())
        }
        require(callerCodeSize == 0, "is-contract");

        // Fee token must be already registered
        require(token < numTokens, "token-overflow");

        // Build root
        RootHeader memory rootHeader =
            RootHeader(
                msg.sender,
                merkleTreeRoot,
                commitmentHash,
                uint32(packedTransactions.length),
                token,
                fee
            );
        bytes32 root = keccak256(abi.encode(rootHeader));

        // Root must not have been registered yet
        uint32 rootBlockNumber = s_Roots[root];
        require(rootBlockNumber == 0, "root-already-exists");

        // Register root with current block number
        require(uint256(uint32(block.number)) == block.number);
        s_Roots[root] = uint32(block.number);

        emit RootCommitted(
            root,
            msg.sender,
            token,
            fee,
            uint32(packedTransactions.length),
            merkleTreeRoot,
            commitmentHash
        );
    }
}
