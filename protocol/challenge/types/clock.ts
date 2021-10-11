import { BigNumber as BN } from 'ethers';

class ClockState {
	constructor(
		public tickTime: BN,
		public tockTime: BN,
		public lastFlipped: BN,
		public maxTime: BN,
		public position: number
	) {}
}

export default ClockState;
