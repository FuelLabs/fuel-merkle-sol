// The BlockHeader structure.
class Withdrawal {
	constructor(
		public owner: string,
		public token: string,
		public amount: number,
		public nonce: number
	) {}
}

export default Withdrawal;
