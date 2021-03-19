// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../types/BlockHeader.sol";
import "../types/BlockCommitment.sol";
import "../provers/BlockHeader.sol";
import "../provers/TransactionProof.sol";
import "../utils/Address.sol";

/// @title Withdrawal handler.
library WithdrawalHandler {

    ////////////
    // Events //
    ////////////

    event WithdrawalMade(
        address indexed owner,
        address token,
        uint256 amount,
        uint32 indexed blockHeight,
        bytes32 indexed transactionId,
        uint8 outputIndex,
        uint16 transactionIndex
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Check if the withdrawal has already need processed.
    /// @param s_Withdrawals The withdrawal state.
    /// @param blockHeight The Fuel block height.
    /// @param withdrawalId The withdrawal ID hash.
    /// @return If the withdrawal has already been processed.
    function isWithdrawalProcessed(
        mapping(uint32 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint32 blockHeight,
        bytes32 withdrawalId
    ) internal view returns (bool) {
        return s_Withdrawals[blockHeight][withdrawalId];
    }

    /// @notice Withdraw a coin from the chain.
    /// @param s_BlockCommitments The block commitments.
    /// @param s_Withdrawals The withdrawal state.
    /// @param finalizationDelay The finalization delay.
    /// @param txProof The transaction proof.
    function withdraw(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        mapping(uint32 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint32 finalizationDelay,
        TransactionProof memory txProof
     ) internal {
       // Ensure the transaction has been finalized.
        TransactionProofProver.proveTransactionProof(
            s_BlockCommitments,
            finalizationDelay,
            txProof,
            BlockHeaderProver.AssertFinalized.Finalized
        );

        // Select the specified output.
        Output memory output = txProof.transaction.outputs[
            txProof.inputOutputIndex
        ];

        // Require that the output selected is a withdraw output.
        require(
            output.kind == OutputKind.Withdrawal,
            "output-kind"
        );

        // Transaction id.
        bytes32 transactionId = TransactionLib.computeTransactionId(txProof.transaction);

        // Setup block producer withdrawal ID (i.e. zero).
        bytes32 withdrawalId = keccak256(abi.encodePacked(
            transactionId,
            txProof.transactionIndex,
            txProof.inputOutputIndex
        ));

        // TODO, handle special cases where withdraw contract doens't exist.
        // Use create2 to create this contract here.

        // Set withdrawal as processed.
        s_Withdrawals[txProof.blockHeader.height][withdrawalId] = true;

        // Block bond withdrawal must not have been processed yet.
        require(
            isWithdrawalProcessed(
                s_Withdrawals,
                txProof.blockHeader.height,
                withdrawalId
            ) == false,
            "already-withdrawn"
        );

        // If it is a withdraw, then transfer the tokens out.
        // TODO, the amount has to be either increased or decreased based upon rounding.
        // We should consider holding a mantissa multiplier for 18* tokens.
        IERC20(Address.fromBytes32(output.color)).transfer(
            Address.fromBytes32(output.to),
            output.amount
        );

        // Emit a WithdrawalMade event. 
        emit WithdrawalMade(
            Address.fromBytes32(output.to),
            Address.fromBytes32(output.color),
            output.amount,
            txProof.blockHeader.height,
            transactionId,
            txProof.inputOutputIndex,
            txProof.transactionIndex
        );
    }

    /// @notice Withdraw a block producer bond from a finalizable block.
    /// @param s_Withdrawals The withdrawal state.
    /// @param bondSize The total bond size.
    /// @param blockHeader The Fuel block header. 
    function bondWithdraw(
        mapping(uint32 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint256 bondSize,
        BlockHeader calldata blockHeader
    ) internal {
        // Setup block producer withdrawal ID (i.e. zero).
        bytes32 withdrawalId = bytes32(0);

        // Setup block height.
        uint32 blockHeight = blockHeader.height;

        // Caller must be block producer.
        require(blockHeader.producer == msg.sender, "caller-producer");

        // Set withdrawal as processed.
        s_Withdrawals[blockHeight][withdrawalId] = true;

        // Block bond withdrawal must not have been processed yet.
        require(
            isWithdrawalProcessed(s_Withdrawals, blockHeight, withdrawalId) ==
                false,
            "already-withdrawn"
        );

        // Transfer bond back to block producer.
        payable(msg.sender).transfer(bondSize);

        // Emit a WithdrawalMade event. 
        emit WithdrawalMade(
            msg.sender,
            address(0),
            bondSize,
            blockHeight,
            bytes32(0),
            0,
            0
        );
    }
}