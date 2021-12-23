// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./lib/challenge/ChessClockLib.sol";
import "./lib/challenge/TransactionIVGLib.sol";
import "./lib/Block.sol";
import "./lib/challenge/ChallengeLib.sol";
import "./Fuel.sol";

/// @notice This contract manages a Challenge from initiation to resolution.
/// @dev A Challenge can be resolved at one of many phases. The state of a challenge is maintained by this contract
contract ChallengeManager {
    using ChessClockLib for Clock;

    address public immutable FUEL_ADDRESS;

    constructor(address fuelAddress) {
        FUEL_ADDRESS = fuelAddress;
    }

    /////////////
    // Storage //
    /////////////

    /// @dev Mapping of challenge IDs to live challenges
    // Internal since we explicitly define a getter function (getChallenge)
    mapping(uint256 => Challenge) internal s_liveChallenges;

    /// @dev The total (monotonically increasing) number of challenges (ensuring each has a unique ID)
    uint256 public s_nChallenges = 0;

    /// @notice : Function to flip the clock
    /// @param challenge : The current challenge. Is provided as function parameter for all actions
    function flip(Challenge storage challenge) internal {
        // Flip the clock. If the clock already timed out, end the game.
        // This should rarely occur since player is not incentivised to continue if they have timed out
        bool timedOut = challenge.clock.flip();

        if (timedOut) {
            timeOutInternal(challenge);
        }
    }

    /// @notice Getter function for a challenge, for readability outside of this contract
    /// @param challengeId: The ID of the challenge to get
    /// @return : The challenge object
    function getChallenge(uint256 challengeId) public view returns (Challenge memory) {
        return s_liveChallenges[challengeId];
    }

    ///////////////////////////
    //  Challenge Initiation //
    ///////////////////////////

    /// @notice The function to initiate a new challenge against the block producer for a given posted block
    /// @param blockHeader: The header of the block to challenge
    function initiateChallenge(BlockHeader memory blockHeader) public payable {
        require(msg.value == Fuel(FUEL_ADDRESS).BOND_SIZE(), "Insufficient bond");
        bytes32 blockHeaderHash = BlockLib.computeBlockId(blockHeader);

        // blockHeaderHash must be not already be finalized
        //require(
        //    Fuel(FUEL_ADDRESS).s_BlockCommitments(blockHeaderHash) !=
        //        BlockCommitmentStatus.Committed,
        //    "Block already finalized"
        //);

        // Start a new challenge. Challenger is the sender
        s_liveChallenges[s_nChallenges] = ChallengeLib.initiateChallenge(
            blockHeader,
            msg.sender,
            Fuel(FUEL_ADDRESS).MAX_CLOCK_TIME()
        );
        s_nChallenges += 1;
    }

    ///////////////////////////
    // Transaction IVG Phase //
    ///////////////////////////

    /// @notice Reveal data requested by the challenger
    /// @param challengeId: The ID of the challenge
    /// @param node : The node data to reveal
    /// @dev Only callable by the challenged
    function transactionIVGRevealData(uint256 challengeId, RevealedNode memory node) public {
        Challenge storage challenge = s_liveChallenges[challengeId];
        TransactionIVGLib.revealData(challenge, node);
        flip(challenge);
    }

    /// @notice Request data from the challenged
    /// @param challengeId: The ID of the challenge
    /// @param rightSide : Whether the node requested is the right child (otherwise, left)
    /// @dev Only callable by the challenger
    function transactionIVGRequestData(uint256 challengeId, bool rightSide) public {
        Challenge storage challenge = s_liveChallenges[challengeId];
        TransactionIVGLib.requestData(challenge, rightSide);
        flip(challenge);
    }

    /// @notice Dispute the revealed transaction data. If no dispute, move on to execution IVG
    /// @param challengeId: The ID of the challenge
    /// @param compressedTxData : The compressed transaction data
    /// @dev Only callable by the challenged
    function transactionIVGSliceData(uint256 challengeId, bytes calldata compressedTxData) public {
        Challenge storage challenge = s_liveChallenges[challengeId];
        TransactionIVGLib.sliceTransactionData(challenge, compressedTxData);
        flip(challenge);
    }

    /// @notice Function for challenged to provide compressed and uncompressed transaction objects
    /// @dev Objects are serialized to check they match the hashes found in the transaction IVG
    /// @dev Basic checks of correct transaction formation are carried out,
    /// @dev and the objects are abi-encoded and hashed so further serialization is unnecessary
    /// @param challengeId: The ID of the challenge
    /// @param compressedTransaction: The compressed transaction object
    /// @param uncompressedTransaction: The uncompressed transaction object
    function transactionIVGProvideTransactions(
        uint256 challengeId,
        Transaction memory compressedTransaction,
        Transaction memory uncompressedTransaction
    ) public {
        Challenge storage challenge = s_liveChallenges[challengeId];
        TransactionIVGLib.provideTransactions(
            challenge,
            compressedTransaction,
            uncompressedTransaction
        );
        flip(challenge);
    }

    /// @notice End a game when a player has timed out.
    /// @param challenge : The challenge being played
    /// @dev This function only called internally : assumes timeOut is true.
    function timeOutInternal(Challenge storage challenge) internal {
        ClockPosition currentPlayer = challenge.clock.position;

        address winner;

        // If clock ran out when clock state was 'tick' (= challenged), winner is challenger
        // In this case, refund the challenger's bond and penalize challenged
        if (currentPlayer == ClockPosition.tick) {
            winner = challenge.challenger;
            payable(winner).transfer(Fuel(FUEL_ADDRESS).BOND_SIZE());
        }
        // Otherwise, burn the challenger's bond
        else {
            winner = challenge.challenged;
            address(0).transfer(Fuel(FUEL_ADDRESS).BOND_SIZE());
        }
    }

    /// @notice End a game when a player has timed out.
    /// @param challengeId : The challenge being played
    /// @dev Anyone can call this function. timeOut is not assumed to be true.
    function timeOut(uint256 challengeId) public {
        Challenge storage challenge = s_liveChallenges[challengeId];
        challenge.clock.timeOut();
        timeOutInternal(challenge);
        delete s_liveChallenges[challengeId];
    }
}
