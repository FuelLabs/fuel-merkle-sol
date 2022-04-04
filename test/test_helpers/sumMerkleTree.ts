/// Some useful helper methods for testing Merkle trees.
import { ethers } from 'hardhat';
import { BigNumber as BN, Contract } from 'ethers';
import { constructTree, getProof } from '@fuel-ts/merklesum';
import { padBytes } from '../utils/utils';

// Build a tree, generate a proof for a given leaf (with optional tampering), and verify using contract
async function checkVerify(
	msto: Contract,
	numLeaves: number,
	leafNumber: number,
	tamper_data: boolean,
	tamper_sum: boolean
): Promise<boolean> {
	const data = [];
	const keys = [];
	const sums = [];
	const size = numLeaves;
	for (let i = 0; i < size; i += 1) {
		data.push(BN.from(i).toHexString());
		keys.push(BN.from(i).toHexString());
		sums.push(BN.from(i));
	}

	const nodeToProve = leafNumber - 1;
	const nodes = constructTree(sums, data);
	const proof = getProof(nodes, nodeToProve);
	const root = nodes[nodes.length - 1];

	let dataToProve = data[nodeToProve];
	let sumToProve = sums[nodeToProve];

	if (tamper_data) {
		// Introduce bad data:
		const badData = ethers.utils.formatBytes32String('badData');
		dataToProve = badData;
	}

	if (tamper_sum) {
		// Introduce bad data:
		const badSum = BN.from(42);
		sumToProve = badSum;
	}

	await msto.verify(
		root.hash,
		root.sum,
		dataToProve,
		sumToProve,
		proof,
		padBytes(keys[nodeToProve]),
		keys.length
	);

	const result = await msto.verified();

	return result;
}

export default checkVerify;
