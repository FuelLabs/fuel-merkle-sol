import Transaction from './types/transaction';
import Input from './types/input';
import Output from './types/output';
import Witness from './types/witness';
import hash from '../cryptography';
import TXOPointer from './types/txoPointer';
import DigestPointer from './types/digestPointer';
import * as Constants from '../constants';
import { uintToBytes32 } from '../utils';

function generateBytes32(): string {
	return hash('0x');
}

export function randomElem(array: number[]): number {
	return array[Math.floor(Math.random() * array.length)];
}

export function generateInput(iKind: number): Input {
	const i = new Input(
		iKind,
		// utxo Pointer
		new TXOPointer(0, 0, 0),
		// utxo ID
		generateBytes32(),
		// owner
		generateBytes32(),
		// amount
		0,
		// asset_id
		generateBytes32(),
		// witnessIndex
		0,
		// maturity
		42,
		// predicateLength
		0,
		// predicateDataLength
		0,
		// predicate
		'0x',
		// predicateData
		'0x',
		// balanceRoot
		generateBytes32(),
		// stateRoot
		generateBytes32(),
		// contractId
		generateBytes32()
	);
	return i;
}

// Output format depends on input type and whether it is compressed or not
export function generateOutput(oKind: number): Output {
	const o = new Output(
		oKind,
		// to
		generateBytes32(),
		// to Pointer
		new DigestPointer(0, 0),
		// asset_id
		uintToBytes32(0),
		// asset_id Pointer
		new DigestPointer(0, 0),
		// amount
		0,
		// inputIndex
		0,
		// balanceRoot
		generateBytes32(),
		// state root
		generateBytes32(),
		// contract ID
		generateBytes32(),
		// contract ID Pointer
		new DigestPointer(0, 0)
	);
	return o;
}

export function generateWitness(): Witness {
	const data = '0xabcdabcd';
	const dataLength = (data.length - 2) / 2;
	const w = new Witness(dataLength, data);
	return w;
}

// Generates a generic script transaction with 3 coin inputs (and corresponding witnesses) and 3 coin outputs
export function generateTransaction(): Transaction {
	// Generate inputs, outputs and witnesses
	const inputs = [];
	for (let i = 0; i < 3; i += 1) {
		inputs.push(generateInput(0));
	}

	const outputs = [];
	for (let i = 0; i < 3; i += 1) {
		outputs.push(generateOutput(0));
	}

	const witnesses = [];
	for (let i = 0; i < 3; i += 1) {
		witnesses.push(generateWitness());
	}

	const t = new Transaction(
		0,
		// gasPrice, gasLimit, maturity
		1,
		Constants.MAX_GAS_PER_TX,
		42,
		// scriptlength, script, datalength, data
		2,
		'0xabcd',
		2,
		'0xabcd',
		// Generate a random number (0-8) of inputs, outputs, and witnesses
		inputs.length,
		outputs.length,
		witnesses.length,
		generateBytes32(),
		inputs,
		outputs,
		witnesses,
		// bytecodeLength, bytecodeWitnessIndex, staticContractsCount, salt, staticContracts
		1,
		0,
		3,
		generateBytes32(),
		[uintToBytes32(1), uintToBytes32(2), uintToBytes32(3)],
		[new TXOPointer(0, 0, 0), new TXOPointer(0, 0, 0), new TXOPointer(0, 0, 0)]
	);

	return t;
}
