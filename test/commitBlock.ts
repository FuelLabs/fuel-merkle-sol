import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { HarnessObject, setupFuel, produceBlock } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('commitBlock', async () => {
	let env: HarnessObject;

	beforeEach(async () => {
		env = await setupFuel({});
	});

	it('produce a block', async () => {
		// Produce a Fuel block.
		const block = await produceBlock(env);

		// Check for correctness.
		expect(
			await env.fuel.getBlockChildAt(block.blockHeader.previousBlockHash, 0)
		).to.equal(block.blockId);
		expect(
			await env.fuel.getBlockNumChildren(block.blockHeader.previousBlockHash)
		).to.equal(1);
	});
});
