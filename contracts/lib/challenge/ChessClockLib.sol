// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/// @notice The state of the clock.
/// @dev Possible value are "tick"/"tock": which player's clock is live
enum ClockPosition {tick, tock}

/// @notice The state of the chess clock for the challenge
struct Clock {
    uint256 tickTime;
    uint256 tockTime;
    uint256 lastFlipped;
    uint256 maxTime;
    ClockPosition position;
}

/// @notice This contract implements a chess clock between two adversaries.
library ChessClockLib {
    /// @notice Flip the clock from "tick" to "tock" state
    /// @param challengeClock: The clock of the game to be flipped
    /// @return timedOut : Returns true if the clock has already timed out. Used to trigger ending of game from IVG contract.
    function flip(Clock storage challengeClock) external returns (bool timedOut) {
        // If clock state is "tick"
        if (challengeClock.position == ClockPosition.tick) {
            // Increment the current player's time by the time elapsed since their opponent last hit the clock
            // solhint-disable-next-line not-rely-on-time
            challengeClock.tickTime += block.timestamp - challengeClock.lastFlipped;

            // If the player is out of time (i.e. this call to flip came too late), end the game
            if (challengeClock.tickTime > challengeClock.maxTime) {
                return true;
            }
            // Otherwise, just flip the clock
            else {
                challengeClock.position = ClockPosition.tock;
            }
        }
        // Same logic if clock state is "tock"
        else {
            // solhint-disable-next-line not-rely-on-time
            challengeClock.tockTime += block.timestamp - challengeClock.lastFlipped;
            if (challengeClock.tockTime > challengeClock.maxTime) {
                return true;
            } else {
                challengeClock.position = ClockPosition.tick;
            }
        }

        // solhint-disable-next-line not-rely-on-time
        challengeClock.lastFlipped = block.timestamp;

        return false;
    }

    /// @notice Manually check if the current player has timed out
    /// @param challengeClock: The clock of the challenge to check
    /// @dev This function has no restrictions on who can call it
    // If player is out of time, they just won't flip. So opponent (or anyone) can end the game.
    function timeOut(Clock storage challengeClock) external view {
        if (challengeClock.position == ClockPosition.tock) {
            require(
                // solhint-disable-next-line not-rely-on-time
                challengeClock.tockTime + (block.timestamp - challengeClock.lastFlipped) >
                    challengeClock.maxTime,
                "ChessClock/time not up"
            );
        } else if (challengeClock.position == ClockPosition.tick) {
            require(
                // solhint-disable-next-line not-rely-on-time
                challengeClock.tickTime + (block.timestamp - challengeClock.lastFlipped) >
                    challengeClock.maxTime,
                "ChessClock/time not up"
            );
        }
    }
}
