import { BigNumber as BN } from 'ethers';

class RevealedNode {
	constructor(
		public isLeaf: boolean,
		public leftDigest: string,
		public rightDigest: string,
		public leftSum: BN,
		public rightSum: BN,
		public dataStart: number,
		public midpoint: number,
		public dataEnd: number,
		public leafData: string,
		public leafValue: BN
	) {}
}

export default RevealedNode;
