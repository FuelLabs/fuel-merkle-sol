/// @dev The Fuel testing harness.
/// A set of useful helper methods for testing Fuel.
import { ethers } from 'hardhat';
import { BigNumberish, Signer } from 'ethers';
import { TransactionReceipt } from '@ethersproject/abstract-provider';
import { Fuel } from '../typechain/Fuel.d';
import { Token } from '../typechain/Token.d';
import { DSGuard } from '../typechain/DSGuard.d';
import { DSToken } from '../typechain/DSToken.d';
import { PerpetualBurnAuction } from '../typechain/PerpetualBurnAuction.d';
import { LeaderSelection } from '../typechain/LeaderSelection.d';
import { BinaryMerkleTree } from '../typechain/BinaryMerkleTree.d';
import { MerkleSumTree } from '../typechain/MerkleSumTree.d';
import { SparseMerkleTree } from '../typechain/SparseMerkleTree.d';
import { TransactionSerializationLib } from '../typechain/TransactionSerializationLib.d';

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
	binaryMerkleTreeLib: BinaryMerkleTree;
	merkleSumTreeLib: MerkleSumTree;
	sparseMerkleTreeLib: SparseMerkleTree;
	fuel: Fuel;
	token: Token;
	fuelToken: DSToken;
	guard: DSGuard;
	burnAuction: PerpetualBurnAuction;
	leaderSelection: LeaderSelection;
	transactionSerializationLib: TransactionSerializationLib;
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
	// Deploy libraries

	// Deploy binary merkle tree library
	const binaryMerkleTreeLibFactory = await ethers.getContractFactory('BinaryMerkleTree');
	const binaryMerkleTreeLib: BinaryMerkleTree =
		(await binaryMerkleTreeLibFactory.deploy()) as BinaryMerkleTree;
	await binaryMerkleTreeLib.deployed();

	// Deploy merkle sum tree library
	const merkleSumTreeLibFactory = await ethers.getContractFactory('MerkleSumTree');
	const merkleSumTreeLib: MerkleSumTree =
		(await merkleSumTreeLibFactory.deploy()) as MerkleSumTree;
	await merkleSumTreeLib.deployed();

	// Deploy sparse merkle tree library
	const sparseMerkleTreeLibFactory = await ethers.getContractFactory('SparseMerkleTree');
	const sparseMerkleTreeLib: SparseMerkleTree =
		(await sparseMerkleTreeLibFactory.deploy()) as SparseMerkleTree;
	await sparseMerkleTreeLib.deployed();

	// Deploy block library
	const blockLibFactory = await ethers.getContractFactory('BlockLib');
	const blockLib = await blockLibFactory.deploy();
	await blockLib.deployed();

	// Deploy transaction serializer library
	const transactionSerializationLibFactory = await ethers.getContractFactory(
		'TransactionSerializationLib'
	);
	const transactionSerializationLib: TransactionSerializationLib =
		(await transactionSerializationLibFactory.deploy()) as TransactionSerializationLib;
	await transactionSerializationLib.deployed();

	// ---

	// Constructor Arguments.
	const finalizationDelay = opts.finalizationDelay || 100;
	const bond = ethers.utils.parseEther('1.0');
	const maxClockTime = 1_000_000;

	// Initial token amount
	const initialTokenAmount = ethers.utils.parseEther('1000');

	// Factory.
	const fuelFactory = await ethers.getContractFactory('Fuel', {
		libraries: {
			BlockLib: blockLib.address,
		},
	});

	// Deployment.
	const fuel: Fuel = (await fuelFactory.deploy(finalizationDelay, bond, maxClockTime)) as Fuel;

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
	const guard: DSGuard = (await guardFactory.deploy()) as DSGuard;
	await guard.deployed();

	// Deploy token
	const dstokenFactory = await ethers.getContractFactory('DSToken');
	const symbol = ethers.utils.formatBytes32String('FUEL');
	const fuelToken: DSToken = (await dstokenFactory.deploy(symbol)) as DSToken;
	await fuelToken.deployed();

	// Deploy leader selection module
	const leaderSelectionFactory = await ethers.getContractFactory('LeaderSelection');
	const tokenAddress = fuelToken.address;
	const roundLength = 3600; // 1 hour
	const selectionWindowLength = 600; // 10 minutes
	const ticketRatio = ethers.utils.parseEther('10'); // 10 tokens per entry
	const genesisSeed = ethers.utils.formatBytes32String('seed');

	const leaderSelection: LeaderSelection = (await leaderSelectionFactory.deploy(
		tokenAddress,
		roundLength,
		selectionWindowLength,
		ticketRatio,
		genesisSeed
	)) as LeaderSelection;

	// Set guard as DSAuthority on token
	await fuelToken.setAuthority(guard.address);

	// Deploy perpetual auction module
	const burnAuctionFactory = await ethers.getContractFactory('PerpetualBurnAuction');
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
	await fuelToken.functions['mint(uint256)'](initialTokenAmount);

	// Return the Fuel harness object.
	return {
		sparseMerkleTreeLib,
		binaryMerkleTreeLib,
		merkleSumTreeLib,
		fuel,
		token,
		fuelToken,
		guard,
		burnAuction,
		leaderSelection,
		transactionSerializationLib,
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
	const transactionsData = ethers.utils.hexZeroPad('0x', 500);
	const numTransactions = 10;
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
		numTransactions,
		transactionsData,
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
		transactionHash: computeTransactionsHash(transactionsData),
		numTransactions,
		transactionsDataLength: computeTransactionsLength(transactionsData),
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
