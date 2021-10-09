import TXOPointer from './txoPointer';

enum InputKind {
	Coin,
	Contract,
}

class Input {
	constructor(
		public kind: InputKind,
		public pointer: TXOPointer,
		public utxoID: string,
		public owner: string,
		public amount: number,
		public color: string,
		public witnessIndex: number,
		public maturity: number,
		public predicateLength: number,
		public predicateDataLength: number,
		public predicate: string,
		public predicateData: string,
		public balanceRoot: string,
		public stateRoot: string,
		public contractID: string
	) {}
}

export default Input;
