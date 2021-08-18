// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
import "./lib/Cryptography.sol";
import "./vendor/ds/ds-token.sol";

/// @notice This contract performs random leader selection, weighted by deposited token balance
/// @dev Users deposit tickets which authorize them to enter a number of 'submissions' proportional to the deposit
/// @dev A submission is an integer, which is hashed with the senders address. To be accepted, it must be closer to the target than the current best
/// @dev Submissions are accepted during a window at the end of a round, when a new target hash is generated.
/// @dev At the end of the window, the closest hash to the target is the winner, and the sender can be instated as the new leader
/// @dev Deposits are never allowed whilst the target hash is known, to avoid waiting for target hash before depositing.
/// @dev Since s_totalDeposit is monotonically increasing, withdawals are allowed at any time
contract LeaderSelection {
    ////////////////
    // Immutables //
    ////////////////

    /// @dev The address of the deposit token
    address public immutable TOKEN_ADDRESS;

    /// @dev The length of each round
    uint256 public immutable ROUND_LENGTH;

    /// @dev The length of the submission window
    uint256 public immutable SUBMISSION_WINDOW_LENGTH;

    /// @dev The ratio of "tickets" to deposited tokens
    uint256 public immutable TICKET_RATIO;

    /////////////
    // Storage //
    /////////////

    /// @dev Store the current leader, and the current candidate for next leader (entry with best hash)
    address public s_leader;
    address public s_candidate;

    /// @dev store the current target hash and the difference of the closest submission from the target
    uint256 public s_closestSubmission;
    bytes32 public s_targetHash;

    /// @dev store the time when next selection process starts (new target is calculated)
    uint256 public s_submissionWindowStart;

    /// @dev Store the time the current round ends (new leader is selected)
    uint256 public s_roundEnd;

    /// @dev store the total balance deposited in the contract
    uint256 public s_totalDeposit;

    /// @dev Store whether the submission window is open (hence a new target hash has been generated)
    bool public s_submissionWindowOpen;

    /// @dev Store the deposited balances of each address
    mapping(address => uint) public s_balances;

    ////////////
    // Events //
    ////////////

    /// @dev Log a new deposit: the depositing address and the deposit amount
    event Deposit(address indexed depositor, uint256 indexed deposit);

    /// @dev Log a new withdrawal: the withdrawing address and the withdrawal amount
    event Withdrawal(address indexed withdrawer, uint256 indexed withdrawal);

    /// @dev Log a submission : the submitting address and the resulting hash
    event Submission(address indexed submitter, uint256 submittedHash);

    /// @dev Log the start of a new round : the new leader and round end time
    event NewRound(address indexed leader, uint256 endTime);

    /// @notice Constructor.
    /// @param tokenAddress: The address of the deposit token used for weighted selection
    /// @param roundLength: The amount of time for after which a new leader can be instated
    /// @param submissionWindowLength: The period of time before the end of a round where deposits/withdrawals are blocked, the target hash is revealed, and submisssions are allowed
    /// @param ticketRatio: The number of deposited tokens per "ticket".
    /// @param genesisSeed: Used to initialize the target hash for the first round
    /// @dev On deployment, there is no leader. The contract accepts deposits for a fixed period. Then a submission window is entered, after which the first leader is instated
    constructor(
        address tokenAddress,
        uint256 roundLength,
        uint256 submissionWindowLength,
        uint256 ticketRatio,
        bytes32 genesisSeed
    ) {
        TOKEN_ADDRESS = tokenAddress;
        ROUND_LENGTH = roundLength;
        SUBMISSION_WINDOW_LENGTH = submissionWindowLength;
        TICKET_RATIO = ticketRatio;
        s_targetHash = genesisSeed;
        s_closestSubmission = type(uint256).max;
        // solhint-disable-next-line not-rely-on-time
        s_roundEnd = block.timestamp + roundLength;
        s_submissionWindowStart = s_roundEnd - submissionWindowLength;
        s_submissionWindowOpen = false;
    }

    /// @notice Deposit tokens in the contract
    /// @param amount: The amount of tokens to deposit
    /// @dev Requires this contract to be approved for at leas 'amount' on TOKEN_ADDRESS
    /// @dev Deposits are frozen during the submission window to avoid pre-calculation of the
    /// @dev minimum ticket number required to approach the revealed target hash
    function deposit(uint256 amount) public {
        // solhint-disable-next-line not-rely-on-time
        require(!s_submissionWindowOpen, "Not allowed in submission window");
        require(amount % TICKET_RATIO == 0, "Not multiple of ticket ratio");
        s_balances[msg.sender] += amount;
        s_totalDeposit += amount;
        DSToken(TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraw tokens from the contract
    /// @param amount: The amount of tokens to withdraw
    /// @dev amount must be a multiple of the ticket ratio
    function withdraw(uint256 amount) public {
        // solhint-disable-next-line not-rely-on-time
        require(amount <= s_balances[msg.sender], "Balance too low");
        require(amount % TICKET_RATIO == 0, "Not multiple of ticket ratio");
        s_balances[msg.sender] -= amount;
        DSToken(TOKEN_ADDRESS).transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Open submission window to allow selection entries.
    /// @dev This is where the target hash is generated, as a function of the old target hash and the total deposit in the contract
    function openSubmissionWindow() public {
        require(!s_submissionWindowOpen, "Submission window already open");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > s_submissionWindowStart, "Too early to open");
        s_targetHash = CryptographyLib.hash(abi.encodePacked(s_targetHash, s_totalDeposit));
        s_submissionWindowOpen = true;
    }

    /// @notice Submit an entry in the current lottery
    /// @param s: The 'ticket number' being entered
    /// @dev Requires the submission window to be open and a target hash to have been generated
    function submit(uint256 s) public {
        require(s_submissionWindowOpen, "submission window not open");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < s_roundEnd, "Round finished");

        // Check user has a high enough balance for submitted integer
        uint256 maxAllowedTicket = s_balances[msg.sender] / TICKET_RATIO;
        require(s < maxAllowedTicket, "Invalid ticket");

        bytes32 hashValue = CryptographyLib.hash(abi.encodePacked(msg.sender, s));

        // Check that entry is closer to the target than the current best
        uint256 difference;
        if (hashValue > s_targetHash) {
            difference = uint256(hashValue) - uint256(s_targetHash);
        } else {
            difference = uint256(s_targetHash) - uint256(hashValue);
        }
        require(difference < s_closestSubmission, "Hash not better");

        // Set new best entry and candidate
        s_closestSubmission = difference;
        s_candidate = msg.sender;

        emit Submission(msg.sender, difference);
    }

    /// @notice Start a new round: End submission window, set new leader and reset lottery state
    function newRound() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= s_roundEnd, "Current round not finished");
        // solhint-disable-next-line not-rely-on-time
        s_roundEnd = block.timestamp + ROUND_LENGTH;
        s_submissionWindowStart = s_roundEnd - SUBMISSION_WINDOW_LENGTH;
        s_closestSubmission = type(uint256).max; /// MAX UINT
        s_leader = s_candidate;
        s_candidate = address(0);
        s_submissionWindowOpen = false;

        emit NewRound(s_leader, s_roundEnd);
    }
}
