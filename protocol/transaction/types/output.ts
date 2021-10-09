import DigestPointer from './digestPointer';

enum OutputKind {
	Coin,
	Contract,
	Withdrawal,
	Change,
	Variable,
	ContractCreated,
}

class Output {
	constructor(
		public kind: OutputKind,
		public to: string,
		public toPointer: DigestPointer,
		public color: string,
		public colorPointer: DigestPointer,
		public amount: number,
		public inputIndex: number,
		public balanceRoot: string,
		public stateRoot: string,
		public contractID: string,
		public contractIDPointer: DigestPointer
	) {}
}

export default Output;
