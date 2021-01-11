// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../TransactionHandler.sol";
import "./BlockHeader.sol";
import "./Output.sol";
import "./RootHeader.sol";
import "./TransactionLeaf.sol";

/// @notice Merkle proof to specific input or output of a transaction in the rollup chain.
struct TransactionProof {
    // Block header
    BlockHeader blockHeader;
    // If a root header is provided
    bool hasRootHeader;
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
    // Transaction leaf bytes
    bytes transactionLeafBytes;
    // Implicit list of unique identifiers being spent (UTXO ID, deposit ID)
    bytes32[] data;
    // Implicit token ID to pay fees in
    uint32 signatureFeeToken;
    // Implicit fee rate
    uint256 signatureFee;
    // Used to verify against an ID
    address address1;
    // Used to verify against an ID
    address address2;
}

/// @title Transaction proof helper functions
library TransactionProofHelper {
    /////////////
    // Methods //
    /////////////

    /// @notice Get UTXO ID from transaction proof.
    /// @param utxo The UTXO.
    /// @return The UTXO ID.
    function getUTXOID(UTXO memory utxo) internal pure returns (bytes32) {
        return keccak256(abi.encode(utxo));
    }

    /// @notice Extract UTXO ID from transaction proof.
    /// @param transactionProof The transaction proof.
    /// @param transactionLeaf The parsed transaction leaf.
    /// @return The UTXO.
    function getUTXO(
        TransactionProof calldata transactionProof,
        TransactionLeaf memory transactionLeaf
    ) internal pure returns (UTXO memory) {
        require(
            transactionProof.inputOutputIndex <= TransactionHandler.OUTPUTS_MAX,
            "output-index-overflow"
        );

        Output memory output =
            transactionLeaf.outputs[transactionProof.inputOutputIndex];

        // Return-type outputs are unspendable
        require(output.t != OutputType.Return, "utxo-return");

        // Construct UTXO
        // TODO do we need to get owners from the proof?
        UTXO memory utxo =
            UTXO(
                getTransactionId(transactionProof),
                transactionProof.inputOutputIndex,
                output.t,
                output.ownerAddress,
                output.amount,
                output.tokenId,
                output.digest,
                output.expiry,
                output.returnOwnerAddress
            );

        return utxo;
    }

    /// @notice Get transaction ID from proof.
    /// @return Transaction ID.
    function getTransactionId(TransactionProof calldata proof)
        internal
        pure
        returns (bytes32)
    {
        // TODO use EIP-712 maybe
        return
            keccak256(
                abi.encode(
                    proof.transactionLeafBytes,
                    proof.data,
                    proof.signatureFeeToken,
                    proof.signatureFee
                )
            );
    }
}
