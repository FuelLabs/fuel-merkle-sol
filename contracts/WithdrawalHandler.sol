// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./TokenHandler.sol";
import "./types/BlockHeader.sol";
import "./types/TransactionProof.sol";
import "./types/WithdrawalMetadata.sol";

/// @title Withdrawal handler
library WithdrawalHandler {
    ////////////
    // Events //
    ////////////

    event WithdrawalMade(
        address indexed owner,
        address token,
        uint256 amount,
        uint32 indexed blockHeight,
        uint16 rootIndex,
        bytes32 indexed transactionLeafHash,
        uint8 outputIndex,
        uint16 transactionIndex
    );

    /////////////
    // Methods //
    /////////////

    /// @notice Check if the withdrawal has already need processed.
    /// @return If the withdrawal has already been processed.
    function isWithdrawalProcessed(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint32 blockHeight,
        bytes32 withdrawalId
    ) internal view returns (bool) {
        return s_Withdrawals[blockHeight][withdrawalId];
    }

    /// @notice Do a withdrawal.
    function withdraw(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        TransactionLeaf memory transactionLeaf,
        TransactionProof calldata transactionProof
    ) internal {
        // Verify transaction proof
        // TODO
        // verifyTransactionProof(transactionProof, AssertFinalized.Finalized)

        Output memory output =
            transactionLeaf.outputs[transactionProof.inputOutputIndex];

        // Output type must be Withdraw
        require(output.t == OutputType.Withdraw, "output-type");

        // Get transaction details
        bytes32 transactionLeafHash =
            keccak256(transactionProof.transactionLeafBytes);

        // Construct withdrawal ID
        WithdrawalMetadata memory withdrawalMetadata =
            WithdrawalMetadata(
                transactionProof.rootIndex,
                transactionLeafHash,
                transactionProof.inputOutputIndex
            );
        bytes32 withdrawalId = keccak256(abi.encode(withdrawalMetadata));

        // This withdrawal must not have been processed yet
        require(
            isWithdrawalProcessed(
                s_Withdrawals,
                transactionProof.blockHeader.height,
                withdrawalId
            ) == false,
            "withdrawal-occured"
        );

        // Transfer amount out

        // Set withdrawal as processed

        emit WithdrawalMade(
            output.ownerAddress,
            output.tokenAddress,
            output.amount,
            transactionProof.blockHeader.height,
            transactionProof.rootIndex,
            transactionLeafHash,
            transactionProof.inputOutputIndex,
            transactionProof.transactionIndex
        );
    }

    /// @notice Withdraw a block producer bond from a finalizable block.
    function bondWithdraw(
        mapping(uint256 => mapping(bytes32 => bool)) storage s_Withdrawals,
        uint256 bondSize,
        BlockHeader calldata blockHeader
    ) internal {
        // Setup block producer withdrawal ID (i.e. zero)
        bytes32 withdrawalId = bytes32(0);

        // Setup block height
        uint32 blockHeight = blockHeader.height;

        // Verify block header is finalized
        // TODO
        // verifyHeader(blockHeader, 0, 0, AssertFinalized.Finalized)

        // Caller must be block producer
        require(blockHeader.producer == msg.sender, "caller-producer");

        // Block bond withdrawal must not have been processed yet
        require(
            isWithdrawalProcessed(s_Withdrawals, blockHeight, withdrawalId) ==
                false,
            "already-withdrawn"
        );

        // Transfer bond back to block producer
        payable(msg.sender).transfer(bondSize);

        // Set withdrawal as processed
        s_Withdrawals[blockHeight][withdrawalId] = true;

        emit WithdrawalMade(
            msg.sender,
            TokenHandler.ETHER_TOKEN_ADDRESS,
            bondSize,
            blockHeight,
            0,
            bytes32(0),
            0,
            0
        );
    }
}
