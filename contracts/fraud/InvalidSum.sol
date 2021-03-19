// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/Block.sol";
import "../provers/TransactionProof.sol";
import "../utils/BinaryMerkleTree.sol";
import "../handlers/Fraud.sol";
import "../types/TransactionProof.sol";

/// @title This will prove an invalid fungiable coin sum fraud.
library InvalidSum {

    /////////////
    // Methods //
    /////////////

    /// @notice Prove an invalid input reference.
    /// @dev Here we check for input reference overflow, existance etc.
    function proveInvalidSum(
        mapping(bytes32 => BlockCommitment) storage s_BlockCommitments,
        uint32 finalizationDelay,
        uint256 bondSize,
        address payable fraudCommitter,
        TransactionProof memory fraudTx
    ) internal {
        // Prove that the fraud tx exists and is not finalized.
        TransactionProofProver.proveTransactionProof(
            s_BlockCommitments,
            finalizationDelay,
            fraudTx,
            BlockHeaderProver.AssertFinalized.NotFinalized
        );

        // Start the input and output sum.
        uint64 totalInputSum = 0;
        uint64 totalOutputSum = 0;

        // Iterate through the inputs.
        for (uint i = 0; i < fraudTx.transaction.inputs.length; i++) {
            Input memory input = fraudTx.transaction.inputs[i];

            // If kind is not a contract.
            if (
                input.kind == InputKind.Coin
                && input.color == fraudTx.color
            ) {
                // Increase input sum.
                totalInputSum += input.amount;
            }
        }

        // Iterate through the outputs.
        for (uint i = 0; i < fraudTx.transaction.outputs.length; i++) {
            Output memory output = fraudTx.transaction.outputs[i];

            // If kind is not a contract.
            if (
                (
                    output.kind == OutputKind.Coin
                    || output.kind == OutputKind.Change
                    || output.kind == OutputKind.Withdrawal
                )
                && output.color == fraudTx.color
            ) {
                // Increase input sum.
                totalOutputSum += output.amount;
            }
        }

        // Check that the total input sum and output sum align. 
        if (totalOutputSum <= totalInputSum) {
            // Revert block.
            FraudHandler.revertBlock(
                s_BlockCommitments,
                bondSize,
                fraudCommitter,
                BlockLib.computeBlockId(fraudTx.blockHeader),
                "sum"
            );
        }
    }
}
