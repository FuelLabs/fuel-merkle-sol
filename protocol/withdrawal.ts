import { BigNumber as BN } from 'ethers';

// The Withdrawal structure.
class Withdrawal {
	constructor(
		public owner: string,
		public token: string,
		public precision: number,
		public amount: BN,
		public nonce: number
	) {}
}

export default Withdrawal;
