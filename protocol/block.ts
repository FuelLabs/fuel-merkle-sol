import { utils, constants, BigNumber as BN } from 'ethers';
import hash from './cryptography';

// The BlockHeader structure.
class BlockHeader {
	constructor(
		public producer: string,
		public previousBlockRoot: string,
		public height: number,
		public blockNumber: number,
		public digestRoot: string,
		public digestHash: string,
		public digestLength: number,
		public transactionRoot: string,
		public transactionSum: BN,
		public transactionHash: string,
		public numTransactions: number,
		public transactionsDataLength: number,
		public validatorSetHash: string,
		public requiredStake: number,
		public withdrawalsRoot: string
	) {}
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
			'uint256',
			'bytes32',
			'uint32',
			'uint32',
			'bytes32',
			'uint256',
			'bytes32',
		],
		[
			blockHeader.producer,
			blockHeader.previousBlockRoot,
			blockHeader.height,
			blockHeader.blockNumber,
			blockHeader.digestRoot,
			blockHeader.digestHash,
			blockHeader.digestLength,
			blockHeader.transactionRoot,
			blockHeader.transactionSum,
			blockHeader.transactionHash,
			blockHeader.numTransactions,
			blockHeader.transactionsDataLength,
			blockHeader.validatorSetHash,
			blockHeader.requiredStake,
			blockHeader.withdrawalsRoot,
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

export default BlockHeader;
