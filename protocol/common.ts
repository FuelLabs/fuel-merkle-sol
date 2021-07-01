/// @dev The Fuel testing Merkle trees.
/// A set of useful helper methods for testing and deploying Merkle trees.
import { ethers } from 'hardhat';
import { Signer, Contract, BigNumber as BN } from 'ethers';

export const EMPTY = '0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
export const ZERO = '0x0000000000000000000000000000000000000000000000000000000000000000';
export const MAX_HEIGHT = 256;

// This is the Merkle Object.
export interface MerkleTreeObject {
	mock: Contract;
	signers: Array<Signer>;
	addresses: Array<string>;
	signer: string;
}

// The deploy method for mock Merkle trees.
export async function deployMerkleTree(mockMerkleTree: string): Promise<MerkleTreeObject> {
	// Mock mekrle tree factory.
	const merkleTreeFactory = await ethers.getContractFactory(mockMerkleTree);

	// Mock mekrle tree.
	const merkleTree = await merkleTreeFactory.deploy();
	// Ensure it's finished deployment.
	await merkleTree.deployed();

	// Set signer.
	const signer = (await ethers.getSigners())[0].address;

	// Return the Merkle tree object.
	return {
		mock: merkleTree,
		signers: await ethers.getSigners(),
		addresses: (await ethers.getSigners()).map((v) => v.address),
		signer,
	};
}

// Does a util exist for this in ethers.js ?
export function uintToBytes32(i: number): string {
	const value = BN.from(i).toHexString();
	let trimmedValue = value.slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}

export function padUint(value: BN): string {
	// uint256 is encoded as 32 bytes, so pad that string.
	let trimmedValue = value.toHexString().slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}

// Does a util exist for this in ethers.js ?
export function padBytes(value: string): string {
	let trimmedValue = value.slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}
