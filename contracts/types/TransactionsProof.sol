// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./BlockHeader.sol";
import "./RootHeader.sol";
import "./TransactionLeaf.sol";

/// @notice Merkle proof to specific input or output of a transaction in the rollup chain.
struct TransactionProof {
    // Block header
    BlockHeader blockHeader;
    // Root header
    RootHeader rootHeader;
    // Index of root in list of roots
    uint16 rootIndex;
    // Merkle proof: neighboring node values
    bytes32[] merkleProof;
    // Index of input or output of transaction
    uint8 inputOutputIndex;
    // Index of transaction in list of transactions in root
    uint16 transactionIndex;
    // Transaction leaf
    TransactionLeaf transactionLeaf;
    // Implicit list of unique identifiers being spent (UTXO ID, deposit ID)
    bytes32[] data;
    // Implicit token ID to pay fees in
    uint32 signatureFeeToken;
    // Implicit fee rate
    uint256 signatureFee;
    // Token address, used for invalid sum proofs
    address tokenAddress;
    // Return owner, used for HTLCs with expired timelock
    address returnOwner;
}
