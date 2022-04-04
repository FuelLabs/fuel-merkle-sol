/// Some useful helper methods for testing binary Merkle trees.
import { ethers } from 'hardhat';
import { BigNumber as BN, Contract } from 'ethers';
import { constructTree, getProof, calcRoot } from '@fuel-ts/merkle';
import { padBytes } from '../utils/utils';

// Build a tree, generate a proof for a given leaf (with optional tampering), and verify using contract
export async function checkVerify(
	bmto: Contract,
	numLeaves: number,
	leafNumber: number,
	tamper: boolean
): Promise<boolean> {
	const data = [];
	const keys = [];
	for (let i = 0; i < numLeaves; i += 1) {
		data.push(BN.from(i).toHexString());
		keys.push(BN.from(i).toHexString());
	}
	const leafToProve = leafNumber - 1;
	const nodes = constructTree(data);
	const root = nodes[nodes.length - 1];
	let dataToProve = data[leafToProve];
	const proof = getProof(nodes, leafToProve);

	if (tamper) {
		// Introduce bad data:
		const badData = ethers.utils.formatBytes32String('badData');
		dataToProve = badData;
	}

	await bmto.verify(root.hash, dataToProve, proof, padBytes(keys[leafToProve]), keys.length);

	const result = await bmto.verified();

	return result;
}

export async function checkAppend(
	bmto: Contract,
	numLeaves: number,
	badProof: boolean
): Promise<boolean> {
	const data = [];
	const size = numLeaves;
	for (let i = 0; i < size; i += 1) {
		data.push(BN.from(i).toHexString());
	}

	const leafToAppend = BN.from(42).toHexString();
	data.push(leafToAppend);
	const nodes = constructTree(data);

	const proof = getProof(nodes, numLeaves);

	if (badProof) {
		proof.push(ethers.constants.HashZero);
	}

	await bmto.append(numLeaves, leafToAppend, proof);

	const root = await bmto.root();
	return root === calcRoot(data);
}
