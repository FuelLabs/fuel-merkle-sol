import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { setupFuel, HarnessObject } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('constructor', async () => {
	let env: HarnessObject;

	beforeEach(async () => {
		env = await setupFuel({});
	});

	// Check construction.
	it('should construct nicely', async () => {
		expect(await env.fuel.BOND_SIZE()).to.equal(env.constructor.bond);
		expect(await env.fuel.FINALIZATION_DELAY()).to.equal(env.constructor.finalizationDelay);
		expect(await env.fuel.NAME()).to.equal(env.constructor.name);
		expect(await env.fuel.VERSION()).to.equal(env.constructor.version);
		expect(await env.fuel.s_BlockTip()).to.equal(0);
	});
});
