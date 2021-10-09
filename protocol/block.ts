import { utils, constants } from 'ethers';
import hash from './cryptography';

// The BlockHeader structure.
export interface BlockHeader {
	producer: string;
	previousBlockHash: string;
	height: number;
	blockNumber: number;
	digestRoot: string;
	digestHash: string;
	digestLength: number;
	transactionRoot: string;
	transactionHash: string;
	numTransactions: number;
	transactionsDataLength: number;
}

// Serialize a blockHeader.
export function serialize(blockHeader: BlockHeader): string {
	return utils.solidityPack(
		[
			'address',
			'bytes32',
			'uint32',
			'uint32',
			'bytes32',
			'bytes32',
			'uint16',
			'bytes32',
			'bytes32',
			'uint32',
			'uint32',
		],
		[
			blockHeader.producer,
			blockHeader.previousBlockHash,
			blockHeader.height,
			blockHeader.blockNumber,
			blockHeader.digestRoot,
			blockHeader.digestHash,
			blockHeader.digestLength,
			blockHeader.transactionRoot,
			blockHeader.transactionHash,
			blockHeader.numTransactions,
			blockHeader.transactionsDataLength,
		]
	);
}

// Empty block.
export const EMPTY_BLOCK_ID = constants.HashZero;

// Compute transactions length.
export function computeTransactionsLength(transactions: string): number {
	return utils.hexDataLength(transactions);
}

// Compute transactions hash.
export function computeTransactionsHash(transactions: string): string {
	return hash(transactions);
}

// Compute digest hash.
export function computeDigestHash(digests: Array<string>): string {
	return hash(utils.solidityPack(['bytes32[]'], [digests]));
}

// Compute the blockId.
export function computeBlockId(blockHeader: BlockHeader): string {
	return hash(serialize(blockHeader));
}
