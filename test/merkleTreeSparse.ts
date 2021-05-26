import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { MerkleTreeObject, deployMerkleTree, uintToBytes32 } from '../protocol/common';
import SparseMerkleTree from '../protocol/sparseMerkleTree/sparseMerkleTree';
import hash from '../protocol/cryptography';
import DeepSparseMerkleSubTree from '../protocol/sparseMerkleTree/deepSparseMerkleSubTree';

chai.use(solidity);
const { expect } = chai;

describe('Sparse Merkle Tree', async () => {
	let smto: MerkleTreeObject;

	beforeEach(async () => {
		smto = await deployMerkleTree('SparseMerkleTree');
	});

	it('Updating and deleting', async () => {
		const smt = new SparseMerkleTree();

		const data = uintToBytes32(42);
		const newData = uintToBytes32(43);

		const n = 100;

		// Add some leaves
		for (let i = 0; i < n; i += 1) {
			const key = hash(uintToBytes32(i));
			smt.update(key, data);
			await smto.mock.update(key, data);
		}
		expect(await smto.mock.root()).to.equal(smt.root);

		// Update an existing leaf to a new value
		smt.update(hash(uintToBytes32(n / 10)), newData);
		await smto.mock.update(hash(uintToBytes32(n / 10)), newData);
		expect(await smto.mock.root()).to.equal(smt.root);

		// Update that leaf back to original value
		smt.update(hash(uintToBytes32(n / 10)), data);
		await smto.mock.update(hash(uintToBytes32(n / 10)), data);
		expect(await smto.mock.root()).to.equal(smt.root);

		// Add an new leaf
		smt.update(hash(uintToBytes32(n + 50)), data);
		await smto.mock.update(hash(uintToBytes32(n + 50)), data);
		expect(await smto.mock.root()).to.equal(smt.root);

		// Delete that leaf
		smt.delete(hash(uintToBytes32(n + 50)));
		await smto.mock.del(hash(uintToBytes32(n + 50)));
		expect(await smto.mock.root()).to.equal(smt.root);
	});

	it('addBranch and update', async () => {
		// Create a SMT
		const smt = new SparseMerkleTree();
		const data = uintToBytes32(42);
		const newData = uintToBytes32(43);

		// Add some leaves
		for (let i = 0; i < 100; i += 1) {
			const key = hash(uintToBytes32(i));
			smt.update(key, data);
		}

		// Create DSMST (sol + ts) and add some branches from the full SMT using compact proofs:
		const dsmst = new DeepSparseMerkleSubTree(smt.root);

		const merkleTreeFactory = await ethers.getContractFactory('DeepSparseMerkleSubTree');
		const dsmsto = await merkleTreeFactory.deploy(smt.root);
		await dsmsto.deployed();

		const keyNumbers = [4, 8, 15, 16, 23, 42];
		const keys: string[] = [];
		for (let i = 0; i < keyNumbers.length; i += 1) {
			keys.push(hash(uintToBytes32(keyNumbers[i])));
		}

		for (let i = 0; i < keys.length; i += 1) {
			const keyToProveMembership = keys[i];
			const valueToProveMembership = data;
			const compactMembershipProof = smt.proveCompacted(keyToProveMembership);
			const res = dsmst.addBranchCompact(
				compactMembershipProof,
				keyToProveMembership,
				valueToProveMembership
			);

			// Solidity needs "0x" for empty byte array
			if (compactMembershipProof.NonMembershipLeafData === '') {
				compactMembershipProof.NonMembershipLeafData = '0x';
			}

			await dsmsto.addBranchCompact(
				compactMembershipProof,
				keyToProveMembership,
				valueToProveMembership
			);

			// Check proof is valid and branch was successfully added for typescript
			expect(res);
		}

		// Update a leaf on the full SMT
		const keyToUpdate = keys[3];
		smt.update(keyToUpdate, newData);

		// Update same leaf on the DSMST (sol + ts)
		dsmst.update(keyToUpdate, newData);
		await dsmsto.update(keyToUpdate, newData);

		// Check roots are equal
		expect(dsmst.root).to.equal(smt.root);
		expect(await dsmsto.root()).to.equal(dsmst.root);
	});
});
