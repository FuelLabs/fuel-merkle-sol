/// @dev The Fuel testing harness.
/// A set of useful helper methods for testing Fuel.
import { ethers } from 'hardhat';
import { BigNumberish, Signer } from 'ethers';
import { TransactionReceipt } from '@ethersproject/abstract-provider';
import { Fuel } from '../typechain/Fuel.d';
import { Token } from '../typechain/Token.d';
import {
	computeTransactionsHash,
	computeDigestHash,
	computeBlockId,
	computeTransactionsLength,
	EMPTY_BLOCK_ID,
	BlockHeader,
} from './block';

// Harness options.
export interface HarnessOptions {
	finalizationDelay?: number;
}

// This is the Harness Object.
export interface HarnessObject {
	fuel: Fuel;
	token: Token;
	signers: Array<Signer>;
	addresses: Array<string>;
	signer: string;
	initialTokenAmount: BigNumberish;
	constructor: {
		finalizationDelay: number;
		bond: BigNumberish;
		name: string;
		version: string;
	};
}

// The setup method for Fuel.
export async function setupFuel(opts: HarnessOptions): Promise<HarnessObject> {
	// Constructor Arguments.
	const finalizationDelay = opts.finalizationDelay || 100;
	const bond = ethers.utils.parseEther('1.0');
	const name = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes('Fuel'), 32);
	const version = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes('v2'), 32);

	// Initial token amount
	const initialTokenAmount = ethers.utils.parseEther('1000');

	// Factory.
	const fuelFactory = await ethers.getContractFactory('Fuel');

	// Deployment.
	const fuel: Fuel = (await fuelFactory.deploy(finalizationDelay, bond, name, version)) as Fuel;

	// Ensure it's finished deployment.
	await fuel.deployed();

	// Deploy a token for deposit testing.
	const tokenFactory = await ethers.getContractFactory('Token');

	// Deploy token.
	const token: Token = (await tokenFactory.deploy()) as Token;

	// Ensure it's finished deployment.
	await token.deployed();

	// Set signer.
	const signer = (await ethers.getSigners())[0].address;

	// Mint token to the first signer.
	await token.mint(signer, initialTokenAmount);

	// Return the Fuel harness object.
	return {
		fuel,
		token,
		signers: await ethers.getSigners(),
		addresses: (await ethers.getSigners()).map((v) => v.address),
		signer,
		initialTokenAmount,
		constructor: {
			finalizationDelay,
			bond,
			name,
			version,
		},
	};
}

// The block object containing pertinent block info.
export interface HarnessBlock {
	blockId: string;
	digests: Array<string>;
	blockHeader: BlockHeader;
	receipt: TransactionReceipt;
}

// This will produce a block given the environment.
export async function produceBlock(env: HarnessObject): Promise<HarnessBlock> {
	// Block properties.
	const producer = env.signer;
	const minimum = await ethers.provider.getBlockNumber();
	const minimumBlock = await ethers.provider.getBlock(minimum);
	const minimumHash = minimumBlock.hash;
	const height = 0;
	const previousBlockHash = EMPTY_BLOCK_ID;
	const transactionRoot = ethers.utils.sha256('0xdeadbeaf');
	const transactions = ethers.utils.hexZeroPad('0x', 500);
	const digestRoot = ethers.utils.sha256('0xdeadbeaf');
	const digests = [
		ethers.utils.hexZeroPad('0xdead', 32),
		ethers.utils.hexZeroPad('0xbeaf', 32),
		ethers.utils.hexZeroPad('0xdeed', 32),
	];

	// Commit block to chain.
	const tx = await env.fuel.commitBlock(
		minimum,
		minimumHash,
		height,
		previousBlockHash,
		transactionRoot,
		transactions,
		digestRoot,
		digests,
		{
			value: env.constructor.bond,
		}
	);
	const receipt = await tx.wait();
	const blockNumber = receipt.blockNumber;

	// Produce a BlockHeader for the block.
	const blockHeader: BlockHeader = {
		producer,
		previousBlockHash,
		height,
		blockNumber,
		digestRoot,
		digestHash: computeDigestHash(digests),
		digestLength: digests.length,
		transactionRoot,
		transactionHash: computeTransactionsHash(transactions),
		transactionLength: computeTransactionsLength(transactions),
	};

	// Compute the block id.
	const blockHash = computeBlockId(blockHeader);

	// Return the interface object.
	return {
		blockHeader,
		receipt,
		blockId: blockHash,
		digests,
	};
}
