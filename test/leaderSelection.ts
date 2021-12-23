import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { HarnessObject, setupFuel } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('leaderSelection', async () => {
	let env: HarnessObject;

	before(async () => {
		env = await setupFuel({});
	});

	it('Check Deployments', async () => {
		// Check initial lottery state
	});

	it('Before submission phase', async () => {
		const amount = ethers.utils.parseEther('300');
		// Deposit should fail : not approved
		const ls = env.leaderSelection;
		await expect(ls.deposit(amount)).to.be.revertedWith('ds-token-insufficient-approval');

		// Successful deposit
		await env.fuelToken.functions['approve(address)'](ls.address);
		await ls.deposit(amount);
		expect(await ls.s_balances(env.signer)).to.equal(amount);

		// Deposit should fail: account balance too low
		await expect(ls.deposit(ethers.utils.parseEther('800'))).to.be.revertedWith(
			'ds-token-insufficient-balance'
		);

		// Deposit should fail: not multiple of ticket ratio
		await expect(ls.deposit(ethers.utils.parseEther('9'))).to.be.revertedWith(
			'Not multiple of ticket ratio'
		);

		// Withdrawal should fail: not multiple of ticket ratio
		await expect(ls.withdraw(ethers.utils.parseEther('9'))).to.be.revertedWith(
			'Not multiple of ticket ratio'
		);

		// Successful withdrawal
		await ls.withdraw(amount);
		expect(await ls.s_balances(env.signer)).to.equal(0);

		// Withdrawal should fail: account balance too low
		await expect(ls.withdraw(amount)).to.be.revertedWith('Balance too low');

		// Opening submission window should fail: too early
		await expect(ls.openSubmissionWindow()).to.be.revertedWith('Too early to open');

		// Submission should fail: submission window not open
		await expect(ls.submit(42)).to.be.revertedWith('submission window not open');

		// End round should fail: too early
		await expect(ls.newRound()).to.be.revertedWith('Current round not finished');
	});

	it('Submission window phase', async () => {
		const ls = env.leaderSelection;

		// Deposit some tokens
		const deposit = ethers.utils.parseEther('300');
		await ls.deposit(deposit);

		// Fast-forward to selection window
		const submissionWindowLength = (await ls.SUBMISSION_WINDOW_LENGTH()).toNumber();
		const roundLength = (await ls.ROUND_LENGTH()).toNumber();
		ethers.provider.send('evm_increaseTime', [roundLength - submissionWindowLength + 60]);

		// Open submission window and check new hash
		const oldHash = await ls.s_targetHash();
		await ls.openSubmissionWindow();
		expect(await ls.s_targetHash()).to.not.equal(oldHash);

		// Submitting a ticket that's too high should fail
		await expect(ls.submit(30)).to.be.revertedWith('Invalid ticket');

		// Submit valid entry
		await ls.submit(29);

		// Submitting a hash that's not better than the current best should fail
		// Calculate integer that makes hash fail
		// This replicates what a user will do when determining whether to submit
		// Note:
		// Solidity's abi.encodePacked encodes an address as 20 bytes
		// ethers.js ethers.utils.defaultAbiCoder().encode encodes it as left-padded 32 bytes
		// so we have to do some awkward string manipulations

		const closestSubmission = await ls.s_closestSubmission();
		const targetHash = await ls.s_targetHash();
		const targetHashValue = ethers.BigNumber.from(targetHash);

		let i = 3;
		let found = false;
		while (found === false) {
			const packed = '0x'.concat(
				ethers.utils.defaultAbiCoder
					.encode(['address', 'uint256'], [env.signer, i])
					.slice(26)
			);
			const expectedHash = ethers.utils.sha256(packed);
			const expectedHashValue = ethers.BigNumber.from(expectedHash);

			let diff = targetHashValue.sub(expectedHashValue);
			if (diff.lt(ethers.BigNumber.from('0'))) {
				diff = diff.mul(-1);
			}

			if (diff.gte(closestSubmission)) {
				await expect(ls.submit(i)).to.be.revertedWith('Hash not better');
				found = true;
			} else {
				i += 1;
			}
		}

		// Second call to openSubmissionWindow should fail
		await expect(ls.openSubmissionWindow()).to.revertedWith('Submission window already open');

		// Deposits should fail during withdrawal/deposit
		const amount = ethers.utils.parseEther('10');
		await expect(ls.deposit(amount)).to.revertedWith('Not allowed in submission window');
	});

	it('New round phase', async () => {
		// Fast-forward to round end
		const ls = env.leaderSelection;
		const submissionWindowLength = (await ls.SUBMISSION_WINDOW_LENGTH()).toNumber();
		ethers.provider.send('evm_increaseTime', [submissionWindowLength]);

		// Submission should fail : too late
		await expect(ls.submit(3)).to.be.revertedWith('Round finished');

		await ls.newRound();

		// Check new leader instated
		expect(await ls.s_leader()).to.equal(env.signer);

		// Check withdrawals/deposits allowed again
		const amount = ethers.utils.parseEther('10');
		const oldBalance = await ls.s_balances(env.signer);
		await ls.deposit(amount);
		expect(await ls.s_balances(env.signer)).to.equal(amount.add(oldBalance));
		expect(await ls.s_candidate()).to.equal(ethers.constants.AddressZero);
	});
});
