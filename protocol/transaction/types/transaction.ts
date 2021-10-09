import Input from './input';
import Output from './output';
import TXOPointer from './txoPointer';
import Witness from './witness';

enum TransactionKind {
	Script,
	Create,
}

// Solidity transaction object
class Transaction {
	constructor(
		public kind: TransactionKind,
		public gasPrice: number,
		public gasLimit: number,
		public maturity: number,
		public scriptLength: number,
		public script: string,
		public scriptDataLength: number,
		public scriptData: string,
		public inputsCount: number,
		public outputsCount: number,
		public witnessesCount: number,
		public receiptsRoot: string,
		public inputs: Input[],
		public outputs: Output[],
		public witnesses: Witness[],
		public bytecodeLength: number,
		public bytecodeWitnessIndex: number,
		public staticContractsCount: number,
		public salt: string,
		public staticContracts: string[],
		public staticContractsPointers: TXOPointer[]
	) {}
}

export default Transaction;
