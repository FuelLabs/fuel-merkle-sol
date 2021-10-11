// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../../types/BlockHeader.sol";
import "./ChessClockLib.sol";
import "./TransactionIVGLib.sol";

struct Challenge {
    BlockHeader blockHeader;
    address challenger;
    address challenged;
    bool transactionRevealed;
    Clock clock;
    TxGame txgame;
    bytes32 uncompressedTransactionHash;
    bytes32 compressedTransactionHash;
}

library ChallengeLib {
    /// @notice The function to initiate a new challenge against the block producer for a given posted block
    /// @param blockHeader: The header of the block to challenge
    /// @return The challenge in its initial state
    function initiateChallenge(
        BlockHeader memory blockHeader,
        address challenger,
        uint256 maxTime
    ) external view returns (Challenge memory) {
        // Instantiate a new clock for this challenge
        // "tick" used to denote challenged's turn, "tock" for challenger.
        // The challenged goes first after the challenge is initiated, so clock begins in 'tick' state
        // solhint-disable-next-line not-rely-on-time
        Clock memory challengeClock = Clock(0, 0, block.timestamp, maxTime, ClockPosition.tick);

        RevealedNode memory revealedNode;

        // Instantiate a new Transaction IVG. First requested Node is the root.
        TxGame memory txgame =
            TxGame(
                RequestedNode(false, blockHeader.transactionRoot),
                revealedNode,
                false,
                "",
                "",
                blockHeader.transactionHash,
                blockHeader.transactionsDataLength
            );

        bytes32 uncompressedTransactionHash;
        bytes32 compressedTransactionHash;

        // Start a new challenge. Challenger is the sender, and challenged is the block producer
        // The challenge begins with an IVG over the transactions, to narrow down the transaction in question
        return
            Challenge(
                blockHeader,
                challenger,
                blockHeader.producer,
                false,
                challengeClock,
                txgame,
                uncompressedTransactionHash,
                compressedTransactionHash
            );
    }
}
