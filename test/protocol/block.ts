import { utils, constants } from "ethers";

// The BlockHeader structure.
interface BlockHeader {
    producer: string;
    previousBlockHash: string;
    height: number;
    blockNumber: number;
    digestCommitmentHash: string;
    digestMerkleRoot: string;
    digestLength: number;
    merkleTreeRoot: string;
    commitmentHash: string;
    length: number;
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
        ],
        [
            blockHeader.producer,
            blockHeader.previousBlockHash,
            blockHeader.height,
            blockHeader.blockNumber,
            blockHeader.digestCommitmentHash,
            blockHeader.digestMerkleRoot,
            blockHeader.digestLength,
            blockHeader.merkleTreeRoot,
            blockHeader.commitmentHash,
            blockHeader.length,
        ],
    );
}

// Empty block.
export const EMPTY_BLOCK_ID = constants.HashZero;

// Compute transactions length.
export function computeTransactionsLength(transactions: string): number {
    return utils.hexDataLength(transactions);
}

// Compute commitment hash.
export function computeCommitmentHash(transactions: string): string {
    return utils.sha256(transactions);
}

// Compute digest commitment hash.
export function computeDigestCommitmentHash(digests: Array<string>): string {
    return utils.sha256(utils.solidityPack(
        [ 'bytes32[]' ],
        [ digests ],
    ));
}

// Compute the blockId.
export function computeBlockId(blockHeader: BlockHeader): string {
    return utils.sha256(serialize(blockHeader));
}