import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { BigNumber as BN } from 'ethers';
import { HarnessObject, setupFuel } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('deposit', async () => {
	let env: HarnessObject;

	beforeEach(async () => {
		env = await setupFuel({});

		// Approve the Fuel contract.
		await env.token.approve(env.fuel.address, env.initialTokenAmount);
	});

	it('check token balance', async () => {
		expect(await env.token.balanceOf(env.signer)).to.be.equal(env.initialTokenAmount);
	});

	it('bridge precision checks', async () => {
		// Deposit with precisionFactor too high should fail
		const precisionFactor = (await env.token.decimals()) + 1;
		await expect(
			env.fuel.deposit(
				env.signer,
				env.token.address,
				precisionFactor,
				ethers.utils.parseEther('1')
			)
		).to.be.revertedWith('resulting-precision-too-low');
		await expect(
			env.fuel.deposit(
				env.signer,
				env.token.address,
				precisionFactor,
				ethers.utils.parseEther('15')
			)
		).to.be.revertedWith('resulting-precision-too-low');
	});

	it('make a deposit with the token', async () => {
		// Make some deposit.
		let totalDeposited = BN.from(0);
		const depositAmount: BN = ethers.utils.parseEther('1');

		await env.fuel.deposit(
			env.signer,
			env.token.address,
			await env.token.decimals(),
			depositAmount
		);
		totalDeposited = totalDeposited.add(depositAmount);

		await env.fuel.deposit(env.signer, env.token.address, 0, depositAmount);
		totalDeposited = totalDeposited.add(depositAmount);

		// Check the balance of the depositor and the Fuel contract.
		expect(await env.token.balanceOf(env.signer)).to.be.equal(
			env.initialTokenAmount.sub(totalDeposited)
		);
		expect(await env.token.balanceOf(env.fuel.address)).to.be.equal(totalDeposited);
	});
});
