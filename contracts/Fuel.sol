// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./handlers/Deposit.sol";
import "./handlers/Block.sol";
import "./handlers/Transaction.sol";
import "./handlers/Fraud.sol";
import "./handlers/Withdrawal.sol";

import "./provers/BlockHeader.sol";

/// @notice The Fuel v2.0 Optimistic Rollup.
/// @dev In this model, the Fuel contract holds all the working state, with libraries providing ORU logic.
contract Fuel {

    ////////////////
    // Immutables //
    ////////////////

    /// @dev The Fuel block bond size in wei.
    uint256 immutable internal BOND_SIZE;

    /// @dev The Fuel block finalization delay in Ethereum block numbers.
    uint32 immutable internal FINALIZATION_DELAY;

    /// @dev The contract name identifier used for EIP712 signing.
    bytes32 immutable internal NAME;

    /// @dev The version identifier used for EIP712 signing.
    bytes32 immutable internal VERSION;

    /////////////
    // Storage //
    /////////////

    /// @dev Maps Fuel block number => Fuel block hash.
    mapping(bytes32 => bytes32[]) public s_BlockCommitments;

    /// @dev Maps the depositor address => token address => Ethereum block number => token amount.
    mapping(address => mapping(address => mapping(uint32 => uint256)))
        public s_Deposits;

    /// @dev Maps the Ethereum block number => withdrawal hash => is withdrawan bool.
    mapping(uint32 => mapping(bytes32 => bool)) public s_Withdrawals;

    /// @dev Maps the fraud commiter address => Fraud commitment hash => Ethereum block number.
    mapping(address => mapping(bytes32 => uint32)) public s_FraudCommitments;

    /// @dev The Fuel block tip number.
    uint32 public s_BlockTip;

    /// @notice The Fuel ORU construction method.
    /// @dev This will setup the Fuel ORU system.
    /// @param finalizationDelay The delay in block time for Fuel block finalization.
    /// @param bond The bond in Ether put up for each block.
    /// @param name The name string used for EIP712 signing.
    /// @param version The version used for EIP712 signing.
    constructor(
        uint32 finalizationDelay,
        uint256 bond,
        bytes32 name,
        bytes32 version
    ) {
        // Set immutable constants.
        BOND_SIZE = bond;
        FINALIZATION_DELAY = finalizationDelay;
        NAME = name;
        VERSION = version;
    }

    /// @notice Deposit a token.
    /// @param account Address of token owner.
    /// @param token Token address.
    /// @param amount The amount to deposit.
    /// @dev DepositHandler::deposit
    function deposit(address account, address token, uint256 amount) external {
        DepositHandler.deposit(
            s_Deposits,
            msg.sender,
            account,
            amount,
            IERC20(token)
        );
    }

    /// @notice Commit a new block.
    /// @param minimum Minimum Ethereum block number that this commitment is valid for.
    /// @param minimumHash Minimum Ethereum block hash that this commitment is valid for.
    /// @param height Rollup block height.
    /// @dev BlockHandler::commitBlock.
    function commitBlock(
        uint32 minimum,
        bytes32 minimumHash,
        uint32 height,
        bytes32 previousBlockHash,
        bytes32 merkleTreeRoot,
        bytes calldata transactions,
        bytes32 addressMerkleRoot,
        bytes32[] calldata addresses
    ) external payable {
        // Check origin.
        require(tx.origin == msg.sender, "origin-not-caller");

        // To avoid Ethereum re-org attacks, commitment transactions include a minimum.
        // Ethereum block number and block hash. Check will fail if transaction is > 256 block old.
        require(block.number > minimum, "minimum-block-number");
        require(blockhash(minimum) == minimumHash, "minimum-block-hash");

        // Require value be bond size.
        require(msg.value == BOND_SIZE, "bond-size");

        // Transactions packed together in a single bytes store.
        bytes memory packedTransactions = abi.encode(transactions);
        bytes32 commitmentHash = keccak256(packedTransactions);

        // Address commitment hash.
        bytes32 addressCommitmentHash = keccak256(abi.encode(addresses));

        // Create a Fuel block header.
        BlockHeader memory blockHeader =
            BlockHeader(
                msg.sender,
                previousBlockHash,
                height,
                SafeCast.toUint32(block.number),
                addressCommitmentHash,
                addressMerkleRoot,
                SafeCast.toUint16(addresses.length),
                merkleTreeRoot,
                commitmentHash,
                SafeCast.toUint32(packedTransactions.length)
            );

        // Set the new block tip.
        s_BlockTip = BlockHandler.commitBlock(
            s_BlockCommitments,
            blockHeader,
            s_BlockTip
        );
    }

    /// @notice Register a fraud commitment hash.
    /// @param fraudHash The hash of the calldata used for a fraud commitment.
    /// @dev Uses the message sender (caller()) in the commitment.
    /// @dev Fraudhandler::commitFraudHash
    function commitFraudHash(bytes32 fraudHash) external {
        FraudHandler.commitFraudHash(s_FraudCommitments, fraudHash);
    }

    /// @notice Withdraw the block proposer's bond for a finalized block.
    /// @param blockHeader Rollup block header of block to withdraw bond for.
    /// @dev WithdrawalHandler::bondWithdraw
    function bondWithdraw(BlockHeader calldata blockHeader) external {
        // Ensure that the block header provided is real.
        BlockHeaderProver.proveBlockHeader(
            s_BlockCommitments,
            FINALIZATION_DELAY,
            blockHeader,
            BlockHeaderProver.AssertFinalized.Finalized
        );

        // Handle the withdrawal of the bond.
        WithdrawalHandler.bondWithdraw(s_Withdrawals, BOND_SIZE, blockHeader);
    }
}