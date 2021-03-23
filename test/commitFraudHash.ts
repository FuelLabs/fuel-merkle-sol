import chai from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { HarnessObject, setupFuel } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('commitFraudHash', async () => {
	let env: HarnessObject;

	beforeEach(async () => {
		env = await setupFuel({});
	});

	it('commit a fraud hash', async () => {
		// Commit a fraud hash to chain.
		const fraudCommitment = ethers.utils.sha256('0xaa');
		const tx = await env.fuel.commitFraudHash(fraudCommitment);
		const receipt = await tx.wait();
		const committer = env.signer;

		// Check if this fraud hash is there.
		expect(await env.fuel.s_FraudCommitments(committer, fraudCommitment)).to.equal(
			receipt.blockNumber
		);
	});
});
