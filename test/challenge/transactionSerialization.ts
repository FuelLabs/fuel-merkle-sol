import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import Transaction from '../../protocol/transaction/types/transaction';
import {
	generateTransaction,
	generateInput,
	generateOutput,
	generateWitness,
} from '../../protocol/transaction/transactionGenerator';
import { HarnessObject, setupFuel } from '../../protocol/harness';
import * as Constants from '../../protocol/constants';
import { uintToBytes32 } from '../../protocol/utils';

chai.use(solidity);
const { expect } = chai;

describe('Transaction Serialization', async () => {
	let env: HarnessObject;
	let srlzr: Contract;
	let t: Transaction;

	// Before each test, generate a valid script transaction with 3 coin inputs and 3 coin outputs
	// The properties will then be customized to test all the transaction formation checks
	beforeEach(async () => {
		t = generateTransaction();
	});

	before(async () => {
		env = await setupFuel({});

		// Deploy serializer test contract with linked library
		const serializer = await ethers.getContractFactory('TxSerialization', {
			libraries: { TransactionSerializationLib: env.transactionSerializationLib.address },
		});

		srlzr = await serializer.deploy();
		await srlzr.deployed();
	});

	describe('Generic transaction checks', () => {
		it('Should serialize', async () => {
			// A valid transaction should serlialize without reverting
			expect(await srlzr.serialize(t, false));
		});

		it('Should revert : transaction type invalid', async () => {
			t.kind = 2;
			await expect(srlzr.serialize(t, false)).to.be.reverted; // revertedWith not working - hardhat can't infer reason
		});

		it('Should revert : gas limit too high', async () => {
			t.gasLimit = Constants.MAX_GAS_PER_TX + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Gas limit too high');
		});

		it('Should revert : too many inputs', async () => {
			const inputs = [];
			for (let i = 0; i < Constants.MAX_INPUTS + 1; i += 1) {
				inputs.push(generateInput(0));
			}
			t.inputsCount = inputs.length;
			t.inputs = inputs;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Too many inputs');
		});

		it('Should revert : too many outputs', async () => {
			const outputs = [];
			for (let i = 0; i < Constants.MAX_OUTPUTS + 1; i += 1) {
				outputs.push(generateOutput(0));
			}
			t.outputsCount = outputs.length;
			t.outputs = outputs;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Too many outputs');
		});

		it('Should revert : too many witnesses', async () => {
			const witnesses = [];
			for (let i = 0; i < Constants.MAX_WITNESSES + 1; i += 1) {
				witnesses.push(generateWitness());
			}
			t.witnessesCount = witnesses.length;
			t.witnesses = witnesses;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Too many witnesses');
		});

		it('Should revert : inputs length mismatch', async () => {
			t.inputsCount = 2;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('inputs length mismatch');
		});

		it('Should revert : outputs length mismatch', async () => {
			t.outputsCount = 2;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('outputs length mismatch');
		});

		it('Should revert : witnesses length mismatch', async () => {
			t.witnessesCount = 2;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('witnesses length mismatch');
		});
	});

	describe('Script transaction checks', () => {
		it('Should revert : Script cant create contract', async () => {
			t.outputs.push(generateOutput(5));
			t.outputsCount += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Script cannot create contract'
			);
		});

		it('Should revert : Output contract has no corresponding input', async () => {
			t.outputs.push(generateOutput(1));
			t.outputsCount += 1;

			// Contract output points to first input by default, which is coin by default
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Output contract has no input'
			);
		});

		it('Should revert : Script too long', async () => {
			t.scriptLength = Constants.MAX_SCRIPT_LENGTH + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Script too long');
		});

		it('Should revert : Script data too long', async () => {
			t.scriptDataLength = Constants.MAX_SCRIPT_DATA_LENGTH + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('scriptData too long');
		});

		it('Should revert : Incorrect script length', async () => {
			t.script = '0x12345678';
			t.scriptLength = 6;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Incorrect script length');
		});

		it('Should revert : Incorrect script data length', async () => {
			t.scriptData = '0x12345678';
			t.scriptDataLength = 6;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Incorrect scriptData length'
			);
		});
	});

	describe('Create transaction checks', () => {
		it('Should revert : Create cannot have input contract', async () => {
			t.kind = 1;
			t.inputs.push(generateInput(1));
			t.inputsCount += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Create cant have input contract'
			);
		});

		it('Should revert : Create cannot have output contract', async () => {
			t.kind = 1;
			t.outputs.push(generateOutput(1));
			t.outputsCount += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Create cant have output contract'
			);
		});

		it('Should revert : Create cannot have output variable', async () => {
			t.kind = 1;
			t.outputs.push(generateOutput(4));
			t.outputsCount += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Create cant have output variable'
			);
		});

		it('Should revert : Change output must have zero asset_id', async () => {
			const o = generateOutput(3);
			o.asset_id = uintToBytes32(1);
			t.kind = 1;
			t.outputs.push(o);
			t.outputsCount += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Non zero-asset_id change outputs'
			);
		});

		it('Should revert : Multiple change outputs', async () => {
			const o = generateOutput(3);
			t.kind = 1;
			t.outputs.push(o);
			t.outputs.push(o);
			t.outputsCount += 2;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Multiple change outputs');
		});

		it('Should revert : Multiple contractCreate outputs', async () => {
			const o = generateOutput(5);
			t.kind = 1;
			t.outputs.push(o);
			t.outputs.push(o);
			t.outputsCount += 2;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Multiple contractCreate outputs'
			);
		});

		it('Should revert : Create must have contractCreate output', async () => {
			t.kind = 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Must have contractCreate output'
			);
		});

		it('Should revert : bytecode too long', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.bytecodeLength = Constants.MAX_CONTRACT_LENGTH / 4 + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('bytecode too long');
		});

		it('Should revert : bytecode data length does not match', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.witnesses[t.bytecodeWitnessIndex].dataLength = t.bytecodeLength * 4 + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'wrong bytecode data length'
			);
		});

		it('Should revert : bytecode witness index too high', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.bytecodeWitnessIndex = t.witnessesCount + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Witness index too high');
		});

		it('Should revert : Too many static contracts', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.staticContractsCount = Constants.MAX_STATIC_CONTRACTS + 1;
			await expect(srlzr.serialize(t, false)).to.be.reverted; // Actually reverts out of bounds when MAX_STATIC_CONTRACT >= type(uint64).max
		});

		it('Should revert : staticContracts length mismatch', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.staticContractsCount = t.staticContracts.length + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'staticContracts length mismatch'
			);
		});

		it('Should revert : staticContracts not ordered', async () => {
			t.kind = 1;
			const o = generateOutput(5);
			t.outputs.push(o);
			t.outputsCount += 1;
			t.staticContracts[0] = uintToBytes32(4);
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'staticContracts not ordered'
			);
		});
	});

	describe('Input checks', () => {
		it('Should revert : input type invalid', async () => {
			t.inputs[0].kind = 2;
			await expect(srlzr.serialize(t, false)).to.be.reverted; // revertedWith not working - hardhat can't infer reason
		});

		it('Should revert : witness index too high', async () => {
			t.inputs[0].witnessIndex = t.witnessesCount + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Witness index too high');
		});

		it('Should revert : Predicate too long', async () => {
			t.inputs[0].predicateLength = Constants.MAX_PREDICATE_LENGTH + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Predicate too long');
		});

		it('Should revert : PredicateData too long', async () => {
			t.inputs[0].predicateDataLength = Constants.MAX_PREDICATE_DATA_LENGTH + 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('predicateData too long');
		});

		it('Should revert : Incorrect predicate length', async () => {
			t.inputs[0].predicateLength += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Incorrect predicate length'
			);
		});

		it('Should revert : Incorrect predicateData length', async () => {
			t.inputs[0].predicateDataLength += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith(
				'Incorrect predicateData length'
			);
		});
	});

	describe('Output checks', () => {
		it('Should revert : output type invalid', async () => {
			t.outputs[0].kind = 6;
			await expect(srlzr.serialize(t, false)).to.be.reverted; // revertedWith not working - hardhat can't infer reason
		});
	});

	describe('Witness checks', () => {
		it('Should revert : Incorrect witness length', async () => {
			t.witnesses[0].dataLength += 1;
			await expect(srlzr.serialize(t, false)).to.be.revertedWith('Incorect witness length');
		});
	});
});
