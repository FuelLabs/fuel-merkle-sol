import { utils, BytesLike } from 'ethers';

// The hash function for the merkle trees
export default function hash(data: BytesLike): string {
	return utils.sha256(data);
}
