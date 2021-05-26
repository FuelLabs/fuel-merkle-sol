import chai from 'chai';
import { BigNumber as BN } from 'ethers';
import { uintToBytes32 } from '../common';
import { calcRoot } from './sumMerkleTree';

const { expect } = chai;

describe('Sum Merkle Tree', async () => {
	it('Compute root', async () => {
		// Root from Go implementation : Size = 100; data[i] = bytes32(i)
		// const rootAfterLeaves = 'GO ROOT HERE';
		const size = 100;
		const sumAfterLeaves = ((size - 1) * size) / 2;

		const data = [];
		const values = [];
		for (let i = 0; i < size; i += 1) {
			data.push(uintToBytes32(i));
			values.push(BN.from(i));
		}

		const res = calcRoot(values, data);
		const sum = res.sum;

		// Compare results
		expect(sum).to.be.equal(sumAfterLeaves);
	});
});
