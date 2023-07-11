import chai from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { BigNumber as BN, Contract } from 'ethers';
import { calcRoot, constructTree, getProof, hashLeaf } from '@fuel-ts/merkle';
import BinaryMerkleBranch from '@fuel-ts/merkle/dist/types/branch';
import yaml from 'js-yaml';
import fs from 'fs';
import { checkAppend, checkVerify } from './test_helpers/binaryMerkleTree';
import { ZERO } from './utils/constants';
import { padBytes, uintToBytes32 } from './utils/utils';
import { EncodedValue, EncodedValueInput } from './utils/encodedValue';
import ProofTest from './utils/proofTest';

chai.use(solidity);
const { expect } = chai;

describe('binary Merkle tree', async () => {
	let bmtlib: Contract;
	let bmto: Contract;

	before(async () => {
		const merkleFactory = await ethers.getContractFactory('BinaryMerkleTree');
		bmtlib = await merkleFactory.deploy();
		await bmtlib.deployed();
	});

	beforeEach(async () => {
		// Deploy mock contract and link BMT library
		const mockMerkle = await ethers.getContractFactory('MockBinaryMerkleTree', {
			libraries: { BinaryMerkleTree: bmtlib.address },
		});
		bmto = await mockMerkle.deploy();
		await bmto.deployed();
	});

	it('Compute root', async () => {
		const data = [];
		const size = 20;
		for (let i = 0; i < size; i += 1) {
			data.push(BN.from(i).toHexString());
		}
		await bmto.computeRoot(data);
		const result = await bmto.root();
		const res = calcRoot(data);

		// Compare results
		expect(result).to.be.equal(res);
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

	it('Data-driven proofs produce expected verifications', async () => {
		const dir = './test/test_vectors/binary_proofs';

		const executeTest = async (file: string) => {
			const fileData = fs.readFileSync(`${dir}/${file}`, 'utf8');
			const test = yaml.load(fileData) as ProofTest;

			const root: EncodedValue = new EncodedValue(test.root);
			const data: EncodedValue = new EncodedValue(test.data);
			const proofSet: EncodedValue[] = test.proof_set.map(
				(item: EncodedValueInput) => new EncodedValue(item)
			);
			const key: number = +test.proof_index;
			const count: number = +test.num_leaves;

			const verification = await bmto.callStatic.verify(
				root.toString(),
				data.toBuffer(),
				proofSet.map((item) => item.toBuffer()),
				key,
				count
			);
			const expectedVerification: boolean = test.expected_verification;
			expect(verification).to.equal(expectedVerification);
		};

		fs.readdir(dir, (err: Error | null, files: string[]) => {
			files.forEach((file) => executeTest(file));
		});
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

	it('AddBranches and update', async () => {
		// First build a full tree in TS
		const numLeaves = 100;
		const data = [];
		const keys = [];
		const size = numLeaves;

		for (let i = 0; i < size; i += 1) {
			data.push(BN.from(i).toHexString());
			keys.push(BN.from(i).toHexString());
		}

		let nodes = constructTree(data);

		// Build branches for a selection of keys
		const branches: BinaryMerkleBranch[] = [];
		const keyNumbers = [4, 8, 15, 16, 23, 42];
		const keysToAdd: string[] = [];
		for (let i = 0; i < keyNumbers.length; i += 1) {
			keysToAdd.push(uintToBytes32(keyNumbers[i]));
		}

		for (let i = 0; i < keysToAdd.length; i += 1) {
			const keyToAdd = keysToAdd[i];
			const valueToAdd = data[BN.from(keysToAdd[i]).toNumber()];
			const proof = getProof(nodes, BN.from(keysToAdd[i]).toNumber());
			branches.push(new BinaryMerkleBranch(proof, keyToAdd, valueToAdd));
		}

		// Add branches and update a key
		const keyToUpdate = keysToAdd[4]; // Index into 'keyNumbers', not 'keys'
		const newData = BN.from(9999).toHexString();
		await bmto.addBranchesAndUpdate(
			branches,
			nodes[nodes.length - 1].hash,
			keyToUpdate,
			newData,
			numLeaves
		);
		let newSolRoot = await bmto.root();

		// Change data and rebuild tree (ts)
		data[parseInt(keyToUpdate, 16)] = newData;
		nodes = constructTree(data);
		const newTSRoot = nodes[nodes.length - 1].hash;

		// Check roots are equal
		expect(newSolRoot).to.equal(newTSRoot);

		// Trivial cases
		// Tree is empty
		await bmto.addBranchesAndUpdate([], ZERO, ZERO, newData, 0);
		newSolRoot = await bmto.root();
		expect(newSolRoot).to.equal(hashLeaf(newData));

		// Tree has only one leaf
		await bmto.addBranchesAndUpdate(
			[new BinaryMerkleBranch([], ZERO, uintToBytes32(42))],
			hashLeaf(uintToBytes32(42)),
			ZERO,
			uintToBytes32(43),
			1
		);
		newSolRoot = await bmto.root();
		expect(newSolRoot).to.equal(hashLeaf(uintToBytes32(43)));
	});
});
