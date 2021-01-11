// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./AddressHandler.sol";
import "./BlockHandler.sol";
import "./DepositHandler.sol";
import "./RootHandler.sol";
import "./WitnessHandler.sol";

/// @title Fuel optimistic rollup top-level contract
contract Fuel {
    ////////////
    // Events //
    ////////////

    event FraudCommitted(
        uint256 indexed previousTip,
        uint256 indexed currentTip,
        uint256 indexed fraudCode
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
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public s_Deposits;
    mapping(bytes32 => bytes32) public s_FraudCommitments;
    uint256 public s_NumAddresses;
    uint32 public s_NumTokens;
    mapping(bytes32 => bytes32) public s_Penalty;
    mapping(bytes32 => bytes32) public s_Roots;
    mapping(address => uint32) public s_Token;
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
        emit BlockHandler.BlockCommitted(
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

    /// @notice Deposit a token.
    /// @param account Address of token owner.
    /// @param token Token address.
    /// @dev DepositHandler::deposit
    function deposit(address account, address token) external {
        s_NumTokens = DepositHandler.deposit(
            s_Deposits,
            s_Token,
            s_NumTokens,
            account,
            token
        );
    }

    /// @notice Commit a new root.
    /// @param merkleTreeRoot Root of transactions tree.
    /// @param token Token ID for fee payments for this root.
    /// @param fee Feerate for this root.
    /// @param transactions List of transactions.
    /// @dev RootHandler::commitRoot
    function commitRoot(
        bytes32 merkleTreeRoot,
        uint256 token,
        uint256 fee,
        bytes calldata transactions
    ) external {
        RootHandler.commitRoot();
    }

    /// @notice Commit a new block.
    /// @param minimum Minimum Ethereum block number that this commitment is valid for.
    /// @param minimumHash Minimum Ethereum block hash that this commitment is valid for.
    /// @param height Rollup block height.
    /// @param roots List of roots in block.
    /// @dev BlockHandler::commitBlock
    function commitBlock(
        uint32 minimum,
        bytes32 minimumHash,
        uint32 height,
        bytes32[] calldata roots
    ) external payable {}

    /// @notice Commit a new witness. Used for authorizing rollup transactions via an Ethereum smart contract.
    /// @param transactionId Transaction ID to authorize.
    /// @dev WitnessHandler::commitWitness
    function commitWitness(bytes32 transactionId) external {}

    /// @notice Register a new address for cheaper transactions.
    /// @param addr Address to register.
    /// @return New ID assigned to address, or existing ID if already assigned.
    /// @dev AddressHandler::commitAddress
    function commitAddress(address addr) external returns (uint256) {}

    /// @notice Register a fraud commitment hash.
    /// @param fraudHash The hash of the calldata used for a fraud commitment.
    /// @dev Uses the message sender (caller()) in the commitment.
    function commitFraudHash(bytes32 fraudHash) external {}

    //////////////////////////////////////////////////////////////////////////
    /// FRAUD PROOFS BEGIN
    //////////////////////////////////////////////////////////////////////////

    /// @notice Prove that a block was malformed.
    /// @param blockHeader Block header.
    /// @param rootHeader Full root header.
    /// @param rootIndex Index to root in block header.
    /// @param transactions List of transactions committed to in root.
    /// @dev provers::MalformedBlock::proveMalformedBlock
    function proveMalformedBlock(
        bytes calldata blockHeader,
        bytes calldata rootHeader,
        uint16 rootIndex,
        bytes calldata transactions
    ) external {}

    /// @notice Prove that a transaction was invalid.
    /// @param transactionProof Proof.
    /// @dev provers::InvalidTransaction::proveInvalidTransaction
    function proveInvalidTransaction(bytes calldata transactionProof)
        external
    {}

    /// @notice Prove that an input was invalid.
    /// @param proofA First proof.
    /// @param proofB Second proof.
    /// @dev provers::InvalidInput::proveInvalidInput
    function proveInvalidInput(bytes calldata proofA, bytes calldata proofB)
        external
    {}

    /// @notice Prove that a UTXO was double-spent.
    /// @param proofA Proof of UTXO being spent once.
    /// @param proofB Proof of UTXO being spent again.
    /// @dev provers::DoubleSpend::proveDoubleSpend
    function proveDoubleSpend(bytes calldata proofA, bytes calldata proofB)
        external
    {}

    /// @notice Prove that a witness was invalid.
    /// @param transactionProof Memory offset to start of transaction proof.
    /// @param inputProofs Memory offset of start of input proofs.
    /// @dev provers::InvalidWitness::proveInvalidWitness
    function proveInvalidWitness(
        bytes calldata transactionProof,
        bytes calldata inputProofs
    ) external {}

    /// @notice Prove that a transation produced more than it consumed.
    /// @param transactionProof Memory offset to start of transaction proof.
    /// @param inputProofs Memory offset of start of input proofs.
    /// @dev provers::InvalidSum::proveInvalidSum
    function proveInvalidSum(
        bytes calldata transactionProof,
        bytes calldata inputProofs
    ) external {}

    //////////////////////////////////////////////////////////////////////////
    /// FRAUD PROOFS END
    //////////////////////////////////////////////////////////////////////////

    /// @notice Complete a withdrawal.
    /// @param proof Inclusion proof for withdrawal on the rollup chain.
    /// @dev WithdrawalHandler::withdraw
    function withdraw(bytes calldata proof) external {}

    /// @notice Withdraw the block proposer's bond for a finalized block.
    /// @param blockHeader Rollup block header of block to withdraw bond for.
    /// @dev WithdrawalHandler::bondWithdraw
    function bondWithdraw(bytes calldata blockHeader) external {}
}