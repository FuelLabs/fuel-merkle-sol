import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { BigNumber as BN, ethers } from 'ethers';
import { HarnessObject, setupFuel } from '../../protocol/harness';
import hash from '../../protocol/cryptography';
import { calcRoot, constructTree } from '../../protocol/binaryMerkleTree/binaryMerkleTree';
import RevealedNode from '../../protocol/challenge/types/revealedNode';
import Node from '../../protocol/binaryMerkleTree/types/node';
import { uintToBytes32 } from '../../protocol/common';
import { BlockHeader } from '../../protocol/block';

chai.use(solidity);
const { expect } = chai;

describe('Transaction IVG', async () => {
	let env: HarnessObject;

	before(async () => {
		env = await setupFuel({});
	});

	// Construct a set of leaves ("transactions"), and calculate the root and hash
	// Each transaction is 32 bytes long, and there are 8 transactions
	const txs: string[] = [];
	let tx;
	for (let i = 0; i < 8; i += 1) {
		tx = hash(BN.from(i).toHexString()); // some random data (replace with actual transactions later)
		txs.push(tx);
	}

	// Get nodes, merkle tree root, and transaction hash
	let txsConcat = '0x';
	for (let i = 0; i < txs.length; i += 1) {
		txsConcat += txs[i].substring(2);
	}

	let txsDataLength = (txsConcat.length - 2) / 2; // bytes is (chars - 2)/2
	const nodes = constructTree(txs);
	const txRoot = calcRoot(txs);
	const txHash = hash(txsConcat);
	let currentNode: Node;

	it('Initiate challenge', async () => {
		const blockHeader: BlockHeader = {
			producer: env.signer,
			previousBlockHash: uintToBytes32(0),
			height: 0,
			blockNumber: 0,
			digestRoot: uintToBytes32(0),
			digestHash: uintToBytes32(0),
			digestLength: 0,
			transactionRoot: txRoot,
			transactionHash: txHash,
			numTransactions: txs.length,
			transactionsDataLength: txsDataLength,
		};

		const bond = ethers.utils.parseEther('1');
		await env.challengeManager.initiateChallenge(blockHeader, {
			value: bond,
		});
	});

	it('Reveal root node', async () => {
		// Reveal the root node
		currentNode = nodes[nodes.length - 1];
		const revealedNode = new RevealedNode(
			false,
			nodes[currentNode.left].hash,
			nodes[currentNode.right].hash,
			0,
			txsDataLength / 2,
			txsDataLength,
			'0x'
		);
		txsDataLength /= 2;
		// console.log(revealedNode);
		await env.challengeManager.transactionIVGRevealData(0, revealedNode);
	});

	it('Request node', async () => {
		// We'll target the 2nd transaction, so we'll request the left-child except at the last node
		await env.challengeManager.transactionIVGRequestData(0, false);
		// console.log((await env.challengeManager.s_liveChallenges(0)).txgame.requestedNode);
	});

	it('Reveal intermediate node', async () => {
		// Reveal the requested node
		const side = (await env.challengeManager.getChallenge(0)).txgame.requestedNode.side;
		if (side) {
			currentNode = nodes[currentNode.right];
		} else {
			currentNode = nodes[currentNode.left];
		}
		const revealedNode = new RevealedNode(
			false,
			nodes[currentNode.left].hash,
			nodes[currentNode.right].hash,
			0,
			txsDataLength / 2,
			txsDataLength,
			'0x'
		);
		// console.log(revealedNode);
		txsDataLength /= 2;
		await env.challengeManager.transactionIVGRevealData(0, revealedNode);
	});

	it('Request node', async () => {
		// We'll target the 2nd transaction, so we'll request the left-child except at the last node
		await env.challengeManager.transactionIVGRequestData(0, false);
		// console.log((await env.challengeManager.s_liveChallenges(0)).txgame.requestedNode);
	});

	it('Reveal intermediate node', async () => {
		// Reveal the requested node
		const side = (await env.challengeManager.getChallenge(0)).txgame.requestedNode.side;
		if (side) {
			currentNode = nodes[currentNode.right];
		} else {
			currentNode = nodes[currentNode.left];
		}
		const revealedNode = new RevealedNode(
			false,
			nodes[currentNode.left].hash,
			nodes[currentNode.right].hash,
			0,
			txsDataLength / 2,
			txsDataLength,
			'0x'
		);
		// console.log(revealedNode);
		txsDataLength /= 2;
		await env.challengeManager.transactionIVGRevealData(0, revealedNode);
	});

	it('Request node', async () => {
		// Now we target the right child, which is the transaction we want
		await env.challengeManager.transactionIVGRequestData(0, true);
		// console.log((await env.challengeManager.s_liveChallenges(0)).txgame.requestedNode);
	});

	it('Reveal leaf', async () => {
		// Reveal the Leaf
		const revealedNode = new RevealedNode(
			true,
			uintToBytes32(0),
			uintToBytes32(0),
			0 + 32, // Offset to right by one transaction for right child
			txsDataLength / 2 + 32, // ""
			txsDataLength + 32, // ""
			txs[1]
		);
		// console.log(revealedNode);
		await env.challengeManager.transactionIVGRevealData(0, revealedNode);
	});

	it('Get transaction data using slices', async () => {
		await env.challengeManager.transactionIVGSliceData(0, txsConcat);
	});

	it('Check revealed transaction has correct hash', async () => {
		expect((await env.challengeManager.getChallenge(0)).txgame.compressedDataHash).to.equal(
			hash(txs[1])
		);
	});
});
