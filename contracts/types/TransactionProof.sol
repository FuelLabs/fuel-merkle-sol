// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./BlockHeader.sol";
import "./Transaction.sol";

/// @notice Merkle proof to specific input or output of a transaction in the rollup chain.
struct TransactionProof {
    // Block header
    BlockHeader blockHeader;

    // Transaction leaf bytes
    Transaction transaction;

    // Block header MMR proof for previous block hash checks.
    bytes32[] mmrMerkleProof;

    // Merkle proof: neighboring node values
    bytes32[] merkleProof;

    // Index of input or output of transaction
    uint8 inputOutputIndex;

    // Index of transaction in list of transactions in root
    uint16 transactionIndex;

    // Color specifier.
    bytes32 color;

    // Transaction is an empty leaf.
    bool empty;
}
