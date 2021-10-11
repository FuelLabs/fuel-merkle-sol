// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/challenge/ChessClockLib.sol";

contract ClockTest {
    using ChessClockLib for Clock;

    Clock public clock;
    uint256 internal maxTime;
    string public state;

    constructor(uint256 _maxTime) {
        maxTime = _maxTime;
        resetClock();
        state = "game begins";
    }

    function resetClock() internal {
        // solhint-disable-next-line not-rely-on-time
        clock = Clock(0, 0, block.timestamp, maxTime, ClockPosition.tick);
    }

    function flip() public {
        bool timedOut = clock.flip();
        if (timedOut) {
            timeOutInternal();
        } else {
            state = "game continues...";
        }
    }

    function timeOutInternal() internal {
        if (clock.position == ClockPosition.tick) {
            state = "Tick timed out: tock wins!";
        } else {
            state = "Tock timed out: tick wins!";
        }
        resetClock();
    }

    function timeOut() public {
        clock.timeOut();
        timeOutInternal();
    }
}
