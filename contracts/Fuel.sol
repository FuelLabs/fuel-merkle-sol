// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

contract Fuel {
    ////////////
    // Events //
    ////////////

    event AddressIndexed(address indexed owner, uint256 indexed id);
    event BlockCommitted(
        address producer,
        uint256 numTokens,
        uint256 numAddresses,
        bytes32 indexed previousBlockHash,
        uint256 indexed height,
        bytes32[] roots
    );
    event DepositMade(
        address indexed account,
        address indexed token,
        uint256 amount
    );
    event FraudCommitted(
        uint256 indexed previousTip,
        uint256 indexed currentTip,
        uint256 indexed fraudCode
    );
    event RootCommitted(
        bytes32 indexed root,
        address rootProducer,
        uint256 feeToken,
        uint256 fee,
        uint256 rootLength,
        bytes32 indexed merkleTreeRoot,
        bytes32 indexed commitmentHash
    );
    event TokenIndexed(address indexed token, uint256 indexed id);
    event WithdrawalMade(
        address indexed account,
        address token,
        uint256 amount,
        uint256 indexed blockHeight,
        uint256 rootIndex,
        bytes32 indexed transactionLeafHash,
        uint8 outputIndex,
        bytes32 transactionId
    );

    ///////////////
    // Constants //
    ///////////////

    uint256 constant GENESIS_BLOCK_HEIGHT = 0;
    uint256 constant GENESIS_ROOTS_LENGTH = 0;
    uint256 constant NUM_TOKENS_INIT = 1;
    uint256 constant NUM_ADDRESSES_INIT = 1;

    uint256 immutable BOND_SIZE;
    uint256 immutable CHAIN_ID;
    uint256 immutable FINALIZATION_DELAY;
    bytes32 immutable NAME;
    address immutable OPERATOR;
    uint256 immutable PENALTY_DELAY;
    uint256 immutable SUBMISSION_DELAY;
    bytes32 immutable VERSION;

    ///////////
    // State //
    ///////////

    mapping(bytes32 => bytes32) public s_Address;
    mapping(uint256 => bytes32) public s_BlockCommitments;
    mapping(bytes32 => bytes32) public s_BlockTip;
    mapping(bytes32 => bytes32) public s_Deposits;
    mapping(bytes32 => bytes32) public s_FraudCommitments;
    mapping(bytes32 => bytes32) public s_NumAddresses;
    mapping(bytes32 => bytes32) public s_NumTokens;
    mapping(bytes32 => bytes32) public s_Penalty;
    mapping(bytes32 => bytes32) public s_Roots;
    mapping(bytes32 => bytes32) public s_Token;
    mapping(bytes32 => bytes32) public s_Withdrawals;
    mapping(bytes32 => bytes32) public s_Witness;

    /////////////////
    // Constructor //
    /////////////////

    constructor(
        address operator,
        uint256 finalizationDelay,
        uint256 submissionDelay,
        uint256 penaltyDelay,
        uint256 bond,
        bytes32 name,
        bytes32 version,
        uint256 chainId,
        bytes32 genesis
    ) {
        // Implicitly commit genesis block
        s_BlockCommitments[GENESIS_BLOCK_HEIGHT] = genesis;
        emit BlockCommitted(
            operator,
            NUM_TOKENS_INIT,
            NUM_ADDRESSES_INIT,
            genesis,
            GENESIS_BLOCK_HEIGHT,
            new bytes32[](0)
        );

        // Set constants
        BOND_SIZE = bond;
        CHAIN_ID = chainId;
        FINALIZATION_DELAY = finalizationDelay;
        NAME = name;
        OPERATOR = operator;
        PENALTY_DELAY = penaltyDelay;
        SUBMISSION_DELAY = submissionDelay;
        VERSION = version;
    }

    /////////////
    // Methods //
    /////////////
}
