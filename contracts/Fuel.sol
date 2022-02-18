// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./handlers/Deposit.sol";
import "./handlers/Withdrawal.sol";
import "./lib/Cryptography.sol";
import "./lib/Block.sol";
import "./LeaderSelection.sol";
import "./lib/tree/binary/BinaryMerkleTree.sol";

/// @notice The Fuel v2 optimistic rollup system.
contract Fuel {
    ///////////////
    // Constants //
    ///////////////

    // Maximum raw transaction data size in bytes.
    uint32 public constant MAX_COMPRESSED_TX_BYTES = 32000;

    // Maximum number of digests registered in a block.
    uint32 public constant MAX_BLOCK_DIGESTS = 0xFFFF;

    /// @dev The Fuel block bond size in wei.
    uint256 public immutable BOND_SIZE;

    /// @dev The Fuel block finalization delay in Ethereum block.
    uint32 public immutable FINALIZATION_DELAY;

    /// @dev The maximum time each participant has to complete their actions (chess clock) in a block challenge
    uint256 public immutable MAX_CLOCK_TIME;

    /// @dev The address of the leader selection module
    address public immutable LEADER_SELECTION;

    /////////////
    // Storage //
    /////////////

    /// @dev The ID of the most recently committed block header
    bytes32 public s_currentBlockID;

    uint256 internal s_depositNonce;

    /// @dev Maps users to claimable withdrawals (user_address => token_address => amount)
    mapping(address => mapping(address => uint256)) public s_withdrawals;

    ////////////
    // Events //
    ////////////

    event BlockCommitted(bytes32 indexed blockRoot, uint32 indexed height);

    /// @notice Contract constructor.
    constructor(
        uint256 bond,
        uint32 finalizationDelay,
        uint256 maxClockTime,
        address leaderSelection,
        bytes32 genesisValSet,
        uint256 genesisRequiredStake
    ) {
        // Initialize constants
        LEADER_SELECTION = leaderSelection;
        BOND_SIZE = bond;
        FINALIZATION_DELAY = finalizationDelay;
        MAX_CLOCK_TIME = maxClockTime;

        // Create the genesis block header
        BlockHeader memory genesisBlockHeader =
            BlockHeader(
                address(0),
                bytes32(0),
                0,
                0,
                bytes32(0),
                bytes32(0),
                0,
                bytes32(0),
                0,
                bytes32(0),
                0,
                0,
                genesisValSet,
                genesisRequiredStake,
                Constants.EMPTY
            );

        bytes32 genesisBlockId = BlockLib.computeBlockId(genesisBlockHeader);
        s_currentBlockID = genesisBlockId;

        emit BlockCommitted(genesisBlockId, 0);
    }

    /// @notice Deposit a token.
    /// @param account Address of token owner.
    /// @param token Token address.
    /// @param precisionFactor The precision for the L2 token compared to L1.
    /// @param amount The amount to deposit.
    /// @dev Note: precision factor: e.g if factor = 3, then 10_000 tokens on layer 1 become 10 tokens on layer 2.
    function deposit(
        address account,
        address token,
        uint8 precisionFactor,
        uint256 amount
    ) external {
        uint256 precision = 10**precisionFactor;
        require((amount / precision) * precision == amount, "resulting-precision-too-low");
        DepositHandler.deposit(msg.sender, account, amount, token, precisionFactor, s_depositNonce);
    }

    /// @notice As `deposit`, but without precision checks
    /// @param account Address of token owner.
    /// @param token Token address.
    /// @param precisionFactor The precision for the L2 token compared to L1.
    /// @param amount The amount to deposit.
    /// @dev WARNING: This function does not check that precision factor <= ERC20.decimals.
    function unsafeDeposit(
        address account,
        address token,
        uint8 precisionFactor,
        uint256 amount
    ) external {
        /// WARNING: If precisionFactor > L1 decimals, tokens may be lost!
        DepositHandler.deposit(msg.sender, account, amount, token, precisionFactor, s_depositNonce);
    }

    /// @notice Withdraw a token.
    /// @param account Address to withdraw token to
    /// @param token Token address.
    /// @param amount The amount to withdraw.
    function withdraw(
        address account,
        address token,
        uint256 amount
    ) external {
        WithdrawalHandler.withdraw(msg.sender, account, amount, token, s_withdrawals);
    }

    struct Withdrawal {
        address owner;
        address token;
        uint256 amount;
        uint8 precision;
        uint256 nonce;
    }

    /// @notice Commit a new block.
    /// @dev Under an honest majority assumption, the block header itself is assumed valid IFF sufficient validator weight has signed.
    /// @dev The block header commits to the validator set for the next block
    /// @param minimumBlockNumber: The minimum ethereum block number for which this commitment is valid
    /// @param expectedBlockHash: The expected block hash of the minimum block number
    /// @param newBlockHeader: The new block header to commit
    /// @param previousBlockHeader: The most recently committed block header
    /// @param validators: The addresses of current validator set
    /// @param stakes : The stakes of the current validator set
    /// @param signatures: The signatures over the proposed block header
    /// @param withdrawals: The withdrawals proposed to be processed with this block commitment
    function commitBlock(
        uint32 minimumBlockNumber,
        bytes32 expectedBlockHash,
        BlockHeader memory newBlockHeader,
        BlockHeader memory previousBlockHeader,
        address[] memory validators,
        uint256[] memory stakes,
        bytes[] memory signatures,
        Withdrawal[] memory withdrawals
    ) public {
        // To avoid Ethereum re-org attacks, commitment transactions include a
        // minimum Ethereum block number and expected block hash.
        // Note: `blockhash` function  will return 0 if transaction is > 256 block old.
        require(block.number > minimumBlockNumber, "minimum-block-number");
        require(blockhash(minimumBlockNumber) == expectedBlockHash, "expected-block-hash");

        // Check provided previousBlockHeader is correct
        require(
            BlockLib.computeBlockId(previousBlockHeader) == s_currentBlockID,
            "incorrect-previous-block"
        );

        // Check new block height is exactly old height + 1
        require(newBlockHeader.height == previousBlockHeader.height + 1, "incorrect-block-height");

        // Check validators/stakes provided match validator set hash from previous block header
        require(
            checkValidators(validators, stakes, previousBlockHeader.validatorSetHash),
            "incorrect-validator-set"
        );

        bytes32 newBlockId = BlockLib.computeBlockId(newBlockHeader);

        // Recover validator addresses from the array of signatures over the new block ID
        uint256 totalStake = 0;
        for (uint256 i = 0; i < validators.length; i += 1) {
            // Stop signature verification as soon as the required stake is reached.
            if (totalStake >= previousBlockHeader.requiredStake) {
                break;
            }

            // Can include '0x' for missing signatures to skip ecrecover and minimize gas costs
            if (signatures[i].length == 0) {
                continue;
            }

            if (CryptographyLib.addressFromSignature(signatures[i], newBlockId) == validators[i]) {
                totalStake += stakes[i];
            }
        }

        // Check block has sufficient stake
        require(totalStake >= previousBlockHeader.requiredStake, "block-not-validated");

        // Process withdrawals

        // Calculate the withdrawal ID for each withdrawal to process
        bytes[] memory withdrawalIds = new bytes[](withdrawals.length);
        for (uint256 i = 0; i < withdrawals.length; i += 1) {
            withdrawalIds[i] = abi.encodePacked(computeWithdrawalId(withdrawals[i])); // BinaryMerkleTree requires bytes, not bytes32
        }

        // Check the root of withdrawal IDs is correct
        require(
            BinaryMerkleTree.computeRoot(withdrawalIds) == newBlockHeader.withdrawalsRoot,
            "invalid-withdrawal-set"
        );

        // Set claimable balances for each withdrawal
        uint256 withdrawnAmount;
        for (uint256 i = 0; i < withdrawals.length; i += 1) {
            Withdrawal memory w = withdrawals[i];
            // L2 precision is defined relative to L1 precision.
            // E.g. If a token has 18 decimals of precision on L1, and 10 on L2, then 'precision' here is 8.
            // E.g. For same token precision on L1 and L2, `precision` is 0.
            // Note: Since `precision` is an unsigned integer, precision on L2 must be less than (fewer decimals) or equal to precision on L1.
            withdrawnAmount = w.amount * (10**w.precision);

            s_withdrawals[w.owner][w.token] += withdrawnAmount;
        }

        // Set the new block ID
        s_currentBlockID = newBlockId;

        emit BlockCommitted(newBlockId, newBlockHeader.height);
    }

    function checkValidators(
        address[] memory validators,
        uint256[] memory stakes,
        bytes32 valSetHash
    ) internal pure returns (bool) {
        // TO DO : Remove this once valSet initialization on genesis is implemented
        if (valSetHash == bytes32(0)) {
            return true;
        }
        return CryptographyLib.hash(abi.encodePacked(validators, stakes)) == valSetHash;
    }

    function computeWithdrawalId(Withdrawal memory withdrawal) internal pure returns (bytes32) {
        return
            CryptographyLib.hash(
                abi.encodePacked(
                    withdrawal.owner,
                    withdrawal.token,
                    withdrawal.precision,
                    withdrawal.amount,
                    withdrawal.nonce
                )
            );
    }
}
