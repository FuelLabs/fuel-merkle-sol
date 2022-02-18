import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { Contract, BigNumber as BN } from 'ethers';
import { HarnessObject, setupFuel } from '../protocol/harness';
import BlockHeader, { computeBlockId } from '../protocol/block';
import { ZERO } from '../protocol/constants';
import { calcRoot } from '../protocol/binaryMerkleTree/binaryMerkleTree';
import { calculateValSetHash, compactSign } from '../protocol/validators';
import Withdrawal from '../protocol/withdrawal';
import hash from '../protocol/cryptography';
import { randomAddress, randomInt } from '../protocol/utils';

chai.use(solidity);
const { expect } = chai;

function randomWithdrawal(): Withdrawal {
	return new Withdrawal(
		randomAddress(),
		randomAddress(),
		randomInt(18),
		BN.from(randomInt(1_000_000)), // Amount need to be BN for when it is multiplied by 10**precision
		randomInt(1_000_000)
	);
}

function createWithdrawals(numWithdrawals: number): Withdrawal[] {
	const withdrawals = [];
	for (let i = 0; i < numWithdrawals; i += 1) {
		withdrawals.push(randomWithdrawal());
	}
	return withdrawals;
}

function computeWithdrawalId(withdrawal: Withdrawal): string {
	return hash(
		ethers.utils.solidityPack(
			['address', 'address', 'uint8', 'uint256', 'uint256'],
			[
				withdrawal.owner,
				withdrawal.token,
				withdrawal.precision,
				withdrawal.amount,
				withdrawal.nonce,
			]
		)
	);
}

// Create a simple block (all fields zeroed except height, producer, and previousBlockRoot)
function simpleBlock(producer: string, previousBlockRoot: string, height: number): BlockHeader {
	const header: BlockHeader = {
		producer,
		previousBlockRoot,
		height,
		blockNumber: 0,
		digestRoot: ZERO,
		digestHash: ZERO,
		digestLength: 0,
		transactionRoot: ZERO,
		transactionSum: BN.from(0),
		transactionHash: ZERO,
		numTransactions: 0,
		transactionsDataLength: 0,
		validatorSetHash: ZERO,
		requiredStake: 0,
		withdrawalsRoot: calcRoot([]),
	};

	return header;
}

describe('blockCommitment', async () => {
	let env: HarnessObject;
	let fuel: Contract;
	let ls: Contract;

	// Arrays of committed block headers and their IDs
	const blockHeaders: BlockHeader[] = [];
	const blockIds: string[] = [];
	let root: string;

	// Maximum number of validators is configured in hardhat.config.ts
	const nValidators = 8;

	before(async () => {
		env = await setupFuel({});
		fuel = env.fuel;

		// Run leader selection round to elect signers[0] as leader
		ls = env.leaderSelection;

		// Approve and deposit tokens for a load of validators
		for (let i = 0; i < nValidators; i += 1) {
			await env.fuelToken.connect(env.signers[i]).functions['approve(address)'](ls.address);
			await ls.connect(env.signers[i]).deposit(ethers.utils.parseEther('100'));
		}

		// Fast forward to submission window
		const submissionWindowLength = (await ls.SUBMISSION_WINDOW_LENGTH()).toNumber();
		const roundLength = (await ls.ROUND_LENGTH()).toNumber();
		ethers.provider.send('evm_increaseTime', [roundLength - submissionWindowLength + 60]);

		// Open window and submit
		await ls.openSubmissionWindow();
		await ls.submit(5);

		// Fast forward to new round
		ethers.provider.send('evm_increaseTime', [submissionWindowLength]);
		await ls.newRound();
	});

	it('Check genesis block set correctly', async () => {
		const genesisBlockHeader = simpleBlock(ethers.constants.AddressZero, ZERO, 0);

		blockHeaders.push(genesisBlockHeader);
		blockIds.push(computeBlockId(genesisBlockHeader));

		const currentId = await fuel.s_currentBlockID();
		expect(currentId).to.be.equal(blockIds[0]);
		root = calcRoot(blockIds);
	});

	it('Commit a load of blocks', async () => {
		for (let n = 1; n < 10; n += 1) {
			// Create next block header at correct height, building on current root
			const blockHeader = simpleBlock(env.signer, root, n);

			// Get the validator set to include in the block header
			// Weights currently maintained by LeaderSelection.sol but will be kept in a Fuel V2 contract
			const validators = [];
			const stakes = [];
			let val;
			for (let i = 0; i < nValidators; i += 1) {
				val = await env.signers[i].getAddress();
				validators.push(val);
				stakes.push(await ls.s_balances(val));
			}

			const valSetHash = calculateValSetHash(validators, stakes);
			const totalStake = await ls.s_totalDeposit();

			blockHeader.validatorSetHash = valSetHash;
			blockHeader.requiredStake = totalStake.div(2);

			// Create a batch of withdrawals
			const nWithdrawals = randomInt(20);
			const withdrawals = createWithdrawals(nWithdrawals);
			const withdrawalIds = withdrawals.map((x) => computeWithdrawalId(x));

			// Include the root of the withdrawal IDs in the block header
			blockHeader.withdrawalsRoot = calcRoot(withdrawalIds);

			// Compute the block header
			const blockId = computeBlockId(blockHeader);

			// Sign the block header by validators with enough weight to validate it
			const signatures = [];
			for (let i = 0; i < nValidators; i += 1) {
				signatures.push(await compactSign(env.signers[i], blockId));
			}

			// Commit the block (propsed block header AND previous block header provided)
			const lastBlockNumber = await ethers.provider.getBlockNumber();
			await fuel.commitBlock(
				lastBlockNumber,
				(
					await ethers.provider.getBlock(lastBlockNumber)
				).hash,
				blockHeader,
				blockHeaders[blockHeaders.length - 1],
				validators,
				stakes,
				signatures,
				withdrawals,
				{ gasLimit: 12_000_000 } // Stop ethers from estimating a gas limit which is more than the block gas limit
			);

			// Append block header and ID to arrays
			blockHeaders.push(blockHeader);
			blockIds.push(computeBlockId(blockHeader));

			// Get the new current block ID and check it matches
			const currentId = await fuel.s_currentBlockID();
			expect(currentId).to.be.equal(blockIds[blockIds.length - 1]);

			// Calculate the new root
			root = calcRoot(blockIds);

			// Check withdrawals processed
			for (let i = 0; i < withdrawals.length; i += 1) {
				const w = withdrawals[i];
				expect(await fuel.s_withdrawals(w.owner, w.token)).to.equal(
					// amount * (10 ** precisionFactor) in BigNumber ...
					w.amount.mul(BN.from(10).pow(w.precision))
				);
			}
		}
	});
});
