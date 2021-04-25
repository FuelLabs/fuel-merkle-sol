/// @dev The Fuel testing harness.
/// A set of useful helper methods for testing Fuel.
import { ethers } from 'hardhat';
import { BigNumberish, Signer } from 'ethers';
import { TransactionReceipt } from '@ethersproject/abstract-provider';
import { Fuel } from '../typechain/Fuel.d';
import { Token } from '../typechain/Token.d';
import { DsGuard } from '../typechain/DsGuard.d';
import { DsToken } from '../typechain/DsToken.d';
import { PerpetualBurnAuction } from '../typechain/PerpetualBurnAuction.d';
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
	fuelToken: DsToken;
	guard: DsGuard;
	burnAuction: PerpetualBurnAuction;
	signers: Array<Signer>;
	addresses: Array<string>;
	signer: string;
	initialTokenAmount: BigNumberish;
	constructor: {
		finalizationDelay: number;
		bond: BigNumberish;
	};
}

// The setup method for Fuel.
export async function setupFuel(opts: HarnessOptions): Promise<HarnessObject> {
	// Constructor Arguments.
	const finalizationDelay = opts.finalizationDelay || 100;
	const bond = ethers.utils.parseEther('1.0');

	// Initial token amount
	const initialTokenAmount = ethers.utils.parseEther('1000');

	// Factory.
	const fuelFactory = await ethers.getContractFactory('Fuel');

	// Deployment.
	const fuel: Fuel = (await fuelFactory.deploy(finalizationDelay, bond)) as Fuel;

	// Ensure it's finished deployment.
	await fuel.deployed();

	// Deploy a token for deposit testing.
	const tokenFactory = await ethers.getContractFactory('Token');

	// Deploy token.
	const token: Token = (await tokenFactory.deploy()) as Token;

	// Ensure it's finished deployment.
	await token.deployed();

	// Deploy guard contract (contains auth mapping)
	const guardFactory = await ethers.getContractFactory('DSGuard');
	const guard: DsGuard = (await guardFactory.deploy()) as DsGuard;
	await guard.deployed();

	// Deploy token
	const dstokenFactory = await ethers.getContractFactory('DSToken');
	const symbol = ethers.utils.formatBytes32String('FUEL');
	const fuelToken: DsToken = (await dstokenFactory.deploy(symbol)) as DsToken;
	await fuelToken.deployed();

	// Set guard as DSAuthority on token
	await fuelToken.setAuthority(guard.address);

	// Deploy auction contract
	const burnAuctionFactory = await ethers.getContractFactory('PerpetualBurnAuction');
	const tokenAddress = fuelToken.address;
	const lotSize = 1000; // 1000 tokens
	const auctionDuration = 43200; // 12 hours
	const burnAuction: PerpetualBurnAuction = (await burnAuctionFactory.deploy(
		tokenAddress,
		lotSize,
		auctionDuration
	)) as PerpetualBurnAuction;
	await burnAuction.deployed();

	// Use guard to authorize auction contract to mint tokens

	// 'guard.permit(burnAuction.address,fuelToken.address,sig)' syntax seems to not work when
	// contract has 2 functions with same name & number of args
	// e.g. permit(address,address,bytes32) and permit(bytes32,bytes32,bytes32)
	await guard.functions['permit(address,address,bytes32)'](
		burnAuction.address,
		fuelToken.address,
		await guard.ANY()
	);

	// Set signer.
	const signer = (await ethers.getSigners())[0].address;

	// Mint token to the first signer.
	await token.mint(signer, initialTokenAmount);

	// Return the Fuel harness object.
	return {
		fuel,
		token,
		fuelToken,
		guard,
		burnAuction,
		signers: await ethers.getSigners(),
		addresses: (await ethers.getSigners()).map((v) => v.address),
		signer,
		initialTokenAmount,
		constructor: {
			finalizationDelay,
			bond,
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
