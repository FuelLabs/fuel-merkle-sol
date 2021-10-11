class RevealedNode {
	constructor(
		public isLeaf: boolean,
		public leftDigest: string,
		public rightDigest: string,
		public dataStart: number,
		public midpoint: number,
		public dataEnd: number,
		public leafData: string
	) {}
}

export default RevealedNode;
