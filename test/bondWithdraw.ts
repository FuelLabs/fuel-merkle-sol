import chai from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { HarnessObject, setupFuel, produceBlock } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('bondWithdraw', async () => {
	let env: HarnessObject;

	beforeEach(async () => {
		env = await setupFuel({});
	});

	it('produce a block', async () => {
		// Produce a block.
		const block = await produceBlock(env);

		// Check for correctness.
		expect(await env.fuel.getBlockChildAt(block.blockHeader.previousBlockHash, 0)).to.equal(
			block.blockId
		);
		expect(await env.fuel.getBlockNumChildren(block.blockHeader.previousBlockHash)).to.equal(1);

		// Mine finalization delay.
		for (let i = 0; i < env.constructor.finalizationDelay; i += 1) {
			await ethers.provider.send('evm_mine', []);
		}

		// Pre balance of bond poster.
		const preBalance = await ethers.provider.getBalance(block.blockHeader.producer);

		// Retrieve the bond.
		const withdrawTx = await env.fuel.bondWithdraw(block.blockHeader);
		const withdrawReceipt = await withdrawTx.wait();

		// Post balance.
		const postBalance = await ethers.provider.getBalance(block.blockHeader.producer);

		// Look for an increase in balance.
		const gasUsed = withdrawReceipt.cumulativeGasUsed.mul(withdrawTx.gasPrice);

		// Check increase in balance.
		expect(postBalance).to.equal(preBalance.add(env.constructor.bond).sub(gasUsed));
	});
});
