// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./vendor/ds/ds-token.sol";

/// @notice This contract perpertually auctions off Fuel tokens for ether, which is burned
/// @notice The mechanism is a first price "English" auction
contract PerpetualBurnAuction {
    ////////////////
    // Immutables //
    ////////////////

    /// @dev Store the address of the auctioned token, the auction lot size, and the auction length
    /// @dev These are all immutable constants
    address public immutable TOKEN_ADDRESS;
    uint256 public immutable LOT_SIZE;
    uint256 public immutable AUCTION_DURATION;

    /////////////
    // Storage //
    /////////////

    /// @dev Store the current highest bidder, the highest bid and the auction expiry
    address payable public highestBidder;
    uint256 public highestBid;
    uint256 public auctionExpiry;

    ////////////
    // Events //
    ////////////

    /// @dev Record a new bid: bidding address, and amount of bid
    event Bid(address indexed bidder, uint256 indexed bid);

    /// @dev Record the end of an auction, with winner, winning bid
    event AuctionEnd(address indexed winner, uint256 indexed winningBid);

    /// @notice Constructor.
    constructor(
        address _tokenAddress,
        uint256 _lotSize,
        uint256 _auctionDuration
    ) {
        TOKEN_ADDRESS = _tokenAddress;
        LOT_SIZE = _lotSize;
        AUCTION_DURATION = _auctionDuration;
        startAuction(_auctionDuration);
    }

    /// @notice For convenience, sending a plain ether transaction places a bid (if sufficient gas provided)
    receive() external payable {
        placeBid();
    }

    /// @notice This starts a new auction
    /// @dev Called once by the constructor, then every time an auction ends.
    /// @dev Consequently, there is always exactly one auction in progress.
    /// @param auctionDuration: The length of the auction in seconds.
    /// @dev Duration passed as argument so it's available from the constructor (since Immutable)
    function startAuction(uint256 auctionDuration) internal {
        // solhint-disable-next-line not-rely-on-time
        auctionExpiry = block.timestamp + auctionDuration;
        highestBid = 0;
        highestBidder = address(0);
    }

    /// @notice This is the public function for placing a bid. Bid is payable in ether.
    /// @dev Since the bid is in ether, there are no params
    function placeBid() public payable returns (bool success) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < auctionExpiry, "FuelAuction/Auction-finshed");
        uint256 bid = msg.value;

        // Bid must be at least higher than the current best bid
        require(bid > highestBid, "FuelAuction/Bid-not-higher");

        // Get previous best bid and bidder in order to refund
        address payable prevHighestBidder = highestBidder;
        uint256 prevHighestBid = highestBid;

        // Write new best bid and bidder to storage
        highestBid = bid;
        highestBidder = msg.sender;

        emit Bid(msg.sender, bid);

        // Refund 'outbid' participant
        // We use a low-level call since "transfer" is vulnerable to griefing if prevHighestBidder is a contract with a fallback function that reverts
        // "call" forwards 63/64ths of the remaining gas to the callee, and any revert is caught, meaning the callee can not cause the transaction to fail,
        // and can not consume all the gas: there will always be enough remaining to complete this function.
        // solhint-disable-next-line avoid-low-level-calls
        prevHighestBidder.call{value: prevHighestBid}("");
        return true;
    }

    /// @notice This function is called to settle the auction, and start a new one
    /// @dev An auction only ends once this is called, but anyone can call.
    function endAuction() public returns (bool success) {
        // Auction must have expired
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= auctionExpiry, "FuelAuction/Auction-not-finished");

        /// Burn highest bid, and mint and transfer tokens to winner
        address(0).transfer(address(this).balance);
        DSToken(TOKEN_ADDRESS).mint(highestBidder, LOT_SIZE);

        emit AuctionEnd(highestBidder, highestBid);

        /// Immediately start a new auction
        startAuction(AUCTION_DURATION);

        return true;
    }
}
