// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

contract BurnAuctionGriefer {
    address payable private immutable burnAuction;

    constructor(address payable _burnAuction) {
        burnAuction = _burnAuction;
    }

    function grief() public payable {
        // solhint-disable-next-line avoid-low-level-calls
        burnAuction.call{value: msg.value}("");
    }

    receive() external payable {
        revert("i win");
    }
}
