import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { BigNumber as BN } from 'ethers';
import { MerkleTreeObject, deployMerkleTree } from '../protocol/common';
import {
	calcRoot,
	checkVerify,
	checkAppend,
	checkAddBranch,
	checkUpdate,
} from '../protocol/binaryMerkleTree/binaryMerkleTree';

chai.use(solidity);
const { expect } = chai;

describe('binary Merkle tree', async () => {
	let bmto: MerkleTreeObject;

	beforeEach(async () => {
		bmto = await deployMerkleTree('MockBinaryMerkleTree');
	});

	it('Compute root', async () => {
		const data = [];
		const size = 20;
		for (let i = 0; i < size; i += 1) {
			data.push(BN.from(i).toHexString());
		}
		const result = await bmto.mock.computeRoot(data);
		const res = calcRoot(data);

		// Compare results
		expect(result).to.be.equal(res);
	});

	it('Set root', async () => {
		const root = '0xe4b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
		await bmto.mock.setRoot(root);
		// Check the result
		expect(await bmto.mock.getRoot()).to.be.equal(root);
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
				await checkVerify(bmto, testCases[i].numLeaves, testCases[i].proveLeaf, false)
			).to.equal(true);

			// Tamper with data
			expect(
				await checkVerify(bmto, testCases[i].numLeaves, testCases[i].proveLeaf, true)
			).to.equal(false);
		}
	});

	it('Append', async () => {
		const testCases = [1, 5, 100];
		for (let i = 0; i < testCases.length; i += 1) {
			// Correct proof should succees
			expect(await checkAppend(bmto, testCases[i], false)).to.equal(true);
			// Incorrect proof should fail
			expect(await checkAppend(bmto, testCases[i], true)).to.equal(false);
		}
	});

	it('AddBranch', async () => {
		const testCases = [
			{ numLeaves: 100, proveLeaf: 100 },
			{ numLeaves: 100, proveLeaf: 99 },
			{ numLeaves: 99, proveLeaf: 42 },
			{ numLeaves: 1, proveLeaf: 1 },
		];

		for (let i = 0; i < testCases.length; i += 1) {
			// Expect success
			bmto = await deployMerkleTree('MockBinaryMerkleTree');
			expect(
				await checkAddBranch(bmto, testCases[i].numLeaves, testCases[i].proveLeaf)
			).to.equal(true);
		}
	});

	it('Update', async () => {
		const testCases = [
			{ numLeaves: 20, leavesToAdd: [1, 4, 12, 19], leavesToUpdate: [4, 12] },
			{ numLeaves: 100, leavesToAdd: [22, 73, 100], leavesToUpdate: [73, 100] },
			{ numLeaves: 10000, leavesToAdd: [342, 1152, 600, 1], leavesToUpdate: [1152, 1] },
			{ numLeaves: 2, leavesToAdd: [1, 2], leavesToUpdate: [1, 2] },
			{ numLeaves: 1, leavesToAdd: [1], leavesToUpdate: [1] },
		];

		for (let i = 0; i < testCases.length; i += 1) {
			// Expect success
			bmto = await deployMerkleTree('MockBinaryMerkleTree');
			expect(
				await checkUpdate(
					bmto,
					testCases[i].numLeaves,
					testCases[i].leavesToAdd,
					testCases[i].leavesToUpdate
				)
			).to.equal(true);
		}
	});
});
