// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./handlers/Block.sol";
import "./handlers/BlockHeader.sol";
import "./handlers/Deposit.sol";
import "./handlers/Fraud.sol";
import "./handlers/Withdrawal.sol";

import "./lib/Cryptography.sol";

import "./types/BlockCommitment.sol";

import "./vendor/openzeppelin/SafeCast.sol";

/// @notice The Fuel v2 optimistic rollup system.
/// @dev This contract holds storage and immutable fields, with libraries providing the logic.
contract Fuel {
    ////////////////
    // Immutables //
    ////////////////

    /// @dev The Fuel block bond size in wei.
    uint256 public immutable BOND_SIZE;

    /// @dev The Fuel block finalization delay in Ethereum block.
    uint32 public immutable FINALIZATION_DELAY;

    /////////////
    // Storage //
    /////////////

    /// @dev Maps Fuel block height => Fuel block ID.
    mapping(bytes32 => BlockCommitment) public s_BlockCommitments;

    /// @dev Maps depositor address => token address => Ethereum block number => token amount.
    mapping(address => mapping(address => mapping(uint32 => uint256))) public s_Deposits;

    /// @dev Maps Ethereum block number => withdrawal ID => is withdrawn bool.
    mapping(uint32 => mapping(bytes32 => bool)) public s_Withdrawals;

    /// @dev Maps fraud prover address => fraud commitment hash => Ethereum block number.
    mapping(address => mapping(bytes32 => uint32)) public s_FraudCommitments;

    /// @dev The Fuel block height of the finalized tip.
    uint32 public s_BlockTip;

    /// @notice Contract constructor.
    /// @param finalizationDelay The delay in blocks for Fuel block finalization.
    /// @param bond The bond in wei to put up for each block.
    constructor(uint32 finalizationDelay, uint256 bond) {
        // Set immutable constants.
        BOND_SIZE = bond;
        FINALIZATION_DELAY = finalizationDelay;

        // Set the genesis block to be valid.
        s_BlockCommitments[bytes32(0)].status = BlockCommitmentStatus.Committed;
    }

    /// @notice Deposit a token.
    /// @param account Address of token owner.
    /// @param token Token address.
    /// @param amount The amount to deposit.
    /// @dev DepositHandler::deposit
    function deposit(
        address account,
        address token,
        uint256 amount
    ) external {
        DepositHandler.deposit(s_Deposits, msg.sender, account, amount, IERC20(token));
    }

    /// @notice Commit a new block.
    /// @param minimumNumber Minimum Ethereum block number that this commitment is valid for.
    /// @param expectedHash Ethereum block hash that this commitment is valid for.
    /// @param height Rollup block height.
    /// @param previousBlockHash This is the previous Merkle root.
    /// @param transactionRoot The transaction Merkle tree root.
    /// @param transactions The raw transaction data for this block.
    /// @param digestRoot The Merkle root of the registered digests.
    /// @param digests The digests being registered.
    /// @dev BlockHandler::commitBlock
    function commitBlock(
        uint32 minimumNumber,
        bytes32 expectedHash,
        uint32 height,
        bytes32 previousBlockHash,
        bytes32 transactionRoot,
        bytes calldata transactions,
        bytes32 digestRoot,
        bytes32[] calldata digests
    ) external payable {
        // Only accept calls directly from an EOA.
        // TODO remove this check https://github.com/FuelLabs/fuel-sol/issues/5
        require(tx.origin == msg.sender, "origin-not-caller");

        // To avoid Ethereum re-org attacks, commitment transactions include a
        // minimum Ethereum block number and expected block hash. Check will
        // fail if transaction is > 256 block old.
        require(block.number > minimumNumber, "minimum-block-number");
        require(blockhash(minimumNumber) == expectedHash, "expected-block-hash");

        // Sent value must be exactly bond size.
        require(msg.value == BOND_SIZE, "bond-size");

        // Compute the simple hash of the submitted transactions. If this
        // doesn't match up with the submitted transactions root, it's
        // fraudulent.
        bytes32 transactionHash = CryptographyLib.hash(transactions);

        // Compute the simple hash of the submitted digests.
        bytes32 digestHash = CryptographyLib.hash(abi.encodePacked(digests));

        // Create a Fuel block header.
        BlockHeader memory blockHeader =
            BlockHeader(
                msg.sender,
                previousBlockHash,
                height,
                SafeCast.toUint32(block.number),
                digestRoot,
                digestHash,
                SafeCast.toUint16(digests.length),
                transactionRoot,
                transactionHash,
                SafeCast.toUint32(transactions.length)
            );

        // Process the new block.
        BlockHandler.commitBlock(s_BlockCommitments, blockHeader);
    }

    /// @notice Get a child for a particular block.
    /// @param blockId The block ID.
    /// @param index The child index.
    /// @return The child block hash.
    function getBlockChildAt(bytes32 blockId, uint32 index) external view returns (bytes32) {
        return s_BlockCommitments[blockId].children[index];
    }

    /// @notice Get the number of children for a particular block.
    /// @param blockId The block ID.
    /// @return The number of children.
    function getBlockNumChildren(bytes32 blockId) external view returns (uint256) {
        return s_BlockCommitments[blockId].children.length;
    }

    /// @notice Register a fraud hash.
    /// @param fraudHash The hash of the calldata used for a fraud commitment.
    /// @dev Uses the message sender (caller()) in the commitment.
    /// @dev FraudHandler::commitFraudHash
    function commitFraudHash(bytes32 fraudHash) external {
        FraudHandler.commitFraudHash(s_FraudCommitments, fraudHash);
    }

    /// @notice Withdraw the block proposer's bond for a finalized block.
    /// @param blockHeader Rollup block header of block to withdraw bond for.
    /// @dev WithdrawalHandler::bondWithdraw
    function bondWithdraw(BlockHeader calldata blockHeader) external {
        // Ensure that the block header was previously submitted and is finalizable.
        require(
            BlockHeaderHandler.isBlockHeaderCommitted(s_BlockCommitments, blockHeader),
            "not-committed"
        );
        BlockHeaderHandler.requireBlockHeaderFinalizable(FINALIZATION_DELAY, blockHeader);

        // Handle the withdrawal of the bond.
        WithdrawalHandler.bondWithdraw(s_Withdrawals, BOND_SIZE, blockHeader);
    }
}
