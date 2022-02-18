/// @dev The Fuel testing harness.
/// A set of useful helper methods for testing Fuel.
import { ethers } from 'hardhat';
import { BigNumber as BN, Signer } from 'ethers';
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
import { ChallengeManager } from '../typechain/ChallengeManager.d';
import { ZERO } from './constants';

// Harness options.
export interface HarnessOptions {
	bond?: BN;
	finalizationDelay?: number;
	maxClockTime?: number;
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
	challengeManager: ChallengeManager;
	transactionSerializationLib: TransactionSerializationLib;
	signers: Array<Signer>;
	addresses: Array<string>;
	signer: string;
	initialTokenAmount: BN;
	constructor: {
		bond: BN;
		finalizationDelay: number;
		maxClockTime: number;
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

	// Deploy chess clock library
	const chessClockLibFactory = await ethers.getContractFactory('ChessClockLib');
	const chessClockLib = await chessClockLibFactory.deploy();
	await chessClockLib.deployed();

	// Deploy transaction IVG library
	const transactionIVGLibFactory = await ethers.getContractFactory('TransactionIVGLib', {
		libraries: {
			TransactionSerializationLib: transactionSerializationLib.address,
		},
	});
	const transactionIVGLib = await transactionIVGLibFactory.deploy();
	await transactionIVGLib.deployed();

	// Deploy Challenge  library
	const challengeLibFactory = await ethers.getContractFactory('ChallengeLib');
	const challengeLib = await challengeLibFactory.deploy();
	await challengeLib.deployed();

	// ---

	// Initial token amount
	const initialTokenAmount = ethers.utils.parseEther('1000000');

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
	const validatorRatio = 3; // 1/3 of validators must approve block
	const genesisSeed = ethers.utils.formatBytes32String('seed');

	const leaderSelection: LeaderSelection = (await leaderSelectionFactory.deploy(
		tokenAddress,
		roundLength,
		selectionWindowLength,
		ticketRatio,
		validatorRatio,
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
	const signers = await ethers.getSigners();

	// Mint some Fuel token to all the signers
	for (let i = 0; i < signers.length; i += 1) {
		await fuelToken.functions['mint(address,uint256)'](
			await signers[i].getAddress(),
			ethers.utils.parseEther('1000')
		);
	}

	// Mint some dummy token for deposit testing
	await token.mint(signer, initialTokenAmount);

	// Deploy Fuel main contract

	const fuelFactory = await ethers.getContractFactory('Fuel', {
		libraries: {
			BlockLib: blockLib.address,
			BinaryMerkleTree: binaryMerkleTreeLib.address,
		},
	});
	// Constructor Arguments.
	const bond = opts.bond || ethers.utils.parseEther('1.0');
	const finalizationDelay = opts.finalizationDelay || 100;
	const maxClockTime = opts.maxClockTime || 1_000_000;
	const leaderSelectionAddress = leaderSelection.address;

	// TO DO : validator set initialization on genesis
	const genesisValSet = ZERO;
	const genesisRequiredStake = 0;

	const fuel: Fuel = (await fuelFactory.deploy(
		bond,
		finalizationDelay,
		maxClockTime,
		leaderSelectionAddress,
		genesisValSet,
		genesisRequiredStake
	)) as Fuel;

	// Ensure it's finished deployment.
	await fuel.deployed();

	// Deploy challenge manager
	const challengeManagerFactory = await ethers.getContractFactory('ChallengeManager', {
		libraries: {
			ChallengeLib: challengeLib.address,
			BlockLib: blockLib.address,
			ChessClockLib: chessClockLib.address,
			TransactionIVGLib: transactionIVGLib.address,
		},
	});

	const challengeManager: ChallengeManager = (await challengeManagerFactory.deploy(
		fuel.address
	)) as ChallengeManager;
	await challengeManager.deployed();

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
		challengeManager,
		transactionSerializationLib,
		signers,
		addresses: (await ethers.getSigners()).map((v) => v.address),
		signer,
		initialTokenAmount,
		constructor: {
			bond,
			finalizationDelay,
			maxClockTime,
		},
	};
}
