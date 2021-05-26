import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { BigNumber as BN } from 'ethers';
import { MerkleTreeObject, deployMerkleTree } from '../protocol/common';
import { calcRoot, checkVerify } from '../protocol/sumMerkleTree/sumMerkleTree';
import hash from '../protocol/cryptography';

chai.use(solidity);
const { expect } = chai;

describe('sum Merkle tree', async () => {
	let smto: MerkleTreeObject;

	beforeEach(async () => {
		smto = await deployMerkleTree('MockSumMerkleTree');
	});

	it('Compute root', async () => {
		const data = [];
		const values = [];
		const valuesBN = [];
		const size = 100;
		for (let i = 0; i < size; i += 1) {
			data.push(hash('0xabde'));
			values.push(BN.from(1).toHexString());
			valuesBN.push(BN.from(1));
		}
		const result = await smto.mock.computeRoot(data, values);
		const res = calcRoot(valuesBN, data);

		// Compare results
		expect(res.sum).to.be.equal(100); // True answer
		expect(result[0]).to.be.equal(res.hash);
		expect(result[1]).to.be.equal(res.sum);
	});

	it('Verifications', async () => {
		const testCases = [
			{ numLeaves: 100, proveLeaf: 100 },
			{ numLeaves: 100, proveLeaf: 99 },
			{ numLeaves: 99, proveLeaf: 42 },
			{ numLeaves: 1, proveLeaf: 1 },
		];

		for (let i = 0; i < testCases.length; i += 1) {
			// Expect success
			expect(
				await checkVerify(
					smto,
					testCases[i].numLeaves,
					testCases[i].proveLeaf,
					false,
					false
				)
			).to.equal(true);

			// Tamper with data
			expect(
				await checkVerify(smto, testCases[i].numLeaves, testCases[i].proveLeaf, false, true)
			).to.equal(false);

			// Tamper with sums
			expect(
				await checkVerify(smto, testCases[i].numLeaves, testCases[i].proveLeaf, true, false)
			).to.equal(false);
		}
	});
});
