//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "../types/Transaction.sol";

library TransactionLib {

    /////////////
    // Methods //
    /////////////

    /// @notice Decompress a single input.
    /// @param data The input data in compressed bytes.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/compressed_tx_format.md#inputcoin.
    /// @return _input The input to return.
    function decompressInput(bytes calldata data) internal pure returns (Input memory _input) {
        // Tracking index.
        uint16 index = 0;

        // Decompress the transaction kind.;
        _input.kind = InputKind(uint8(abi.decode(data[index:index + 1], (bytes1))));
        index += 1;

        // Decompress a Coin input.
        if (_input.kind == InputKind.Coin) {
            // The TXO pointer block height.
            _input.pointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _input.pointer.txIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The TXO pointer output index.
            _input.pointer.outputIndex = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The witness index.
            _input.witnessIndex = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The witness index.
            _input.maturity = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The predicate length.
            _input.predicateLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The predicateDataLength.
            _input.predicateDataLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The predicate.
            _input.predicate = abi.decode(data[index:index + _input.predicateLength], (bytes));
            index += _input.predicateLength;

            // The predicate data.
            _input.predicateData = abi.decode(data[index:index + _input.predicateDataLength], (bytes));
            index += _input.predicateDataLength;

            // Set metadata bytesize.
            _input._bytesize = index;

            // Return and stop.
            return _input;
        }

        // Decompress a contract input.
        if (_input.kind == InputKind.Contract) {
            // The Contract TXO pointer block height.
            _input.pointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The Contract TXO pointer block height.
            _input.pointer.txIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The Contract TXO pointer output index.
            _input.pointer.outputIndex = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Set metadata bytesize.
            _input._bytesize = index;

            // Return and stop.
            return _input;
        }   
    }

    /// @notice Decompress a single output.
    /// @param data The output data in compressed bytes.
    /// @return _output The output to return in a sum struct.
    function decompressOutput(bytes calldata data) internal pure returns (Output memory _output) {
        // Tracking index.
        uint16 index = 0;

        // Decompress the transaction kind.;
        _output.kind = OutputKind(uint8(abi.decode(data[index:index + 1], (bytes1))));
        index += 1;

        // Handle the OutputCoin.
        if (_output.kind == OutputKind.Coin) {
            // The TXO pointer block height.
            _output.toPointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.toPointer.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Specify the bytesize of this output.
            _output._bytesize = index;

            // Stop and return.
            return _output;
        }

        // Handle the Contract.
        if (_output.kind == OutputKind.Contract) {
            // Decompress the transaction kind.
            _output.inputIndex = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Specify the bytesize of this output.
            _output._bytesize = index;
            
            // Stop and return.
            return _output;
        }

        // Handle the Withdrawal.
        if (_output.kind == OutputKind.Withdrawal) {
            // The TXO pointer block height.
            _output.toPointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.toPointer.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Specify the bytesize of this output.
            _output._bytesize = index;
            
            // Stop and return.
            return _output;
        }

        // Handle the Change.
        if (_output.kind == OutputKind.Change) {
            // The TXO pointer block height.
            _output.toPointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.toPointer.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Specify the bytesize of this output.
            _output._bytesize = index;
            
            // Stop and return.
            return _output;
        }

        // Handle the Variable.
        if (_output.kind == OutputKind.Variable) {
            // The TXO pointer block height.
            _output.toPointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.toPointer.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.addressIndex = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Specify the bytesize of this output.
            _output._bytesize = index;
            
            // Stop and return.
            return _output;
        }

        // Handle the ContractCreated.
        if (_output.kind == OutputKind.ContractCreated) {
            // The TXO pointer block height.
            _output.contractID = bytes32(abi.decode(data[index:index + 32], (bytes32)));
            index += 32;

            // Specify the bytesize of this output.
            _output._bytesize = index;

            // Stop and return.
            return _output;
        }
    }

    /// @notice Decompress a single witness.
    /// @param data The compressed witness data in bytes.
    /// @return _witness The sum type witness to struct.
    function decompressWitness(bytes calldata data) internal pure returns (Witness memory _witness) {
        // Tracking index.
        uint16 index = 0;

        // The TXO pointer block height.
        _witness.dataLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
        index += 2;

        // The TXO pointer block height.
        _witness.data = abi.decode(data[index:index + _witness.dataLength], (bytes));
        index += _witness.dataLength;

        // Specify the bytesize of this witness.
        _witness._bytesize = index;

        // Stop and return.
        return _witness;
    }

    /// @notice decompress bytes into a Transaction object.
    /// @param data The compressed transaction data.
    /// @return _tx The uncompressed transaction data.
    function decompress(bytes calldata data) internal pure returns (Transaction memory _tx) {
        // Tracking index.
        uint16 index = 0;

        // Decode the transaction kind.;
        _tx.kind = TransactionKind(uint8(abi.decode(data[index:index + 1], (bytes1))));
        index += 1;

        // Decode the gas price.
        _tx.gasPrice = uint64(abi.decode(data[index:index + 8], (bytes8)));
        index += 8;

        // Decode the gas limit.
        _tx.gasPrice = uint64(abi.decode(data[index:index + 8], (bytes8)));
        index += 8;

        // Decode the gas limit.
        _tx.maturity = uint32(abi.decode(data[index:index + 4], (bytes4)));
        index += 4;

        // Script.
        if (_tx.kind == TransactionKind.Script) {
            // Script length.
            _tx.scriptLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Script data length.
            _tx.scriptDataLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The number of inputs in the transaction.
            _tx.inputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The number of outputs in the transaciton.
            _tx.outputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The number of witnesses in the transaction.
            _tx.witnessesCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The script in the transaction.
            _tx.script = abi.decode(data[index:index + _tx.scriptLength], (bytes));
            index += 1;

            // The script data in the transaction.
            _tx.scriptData = abi.decode(data[index:index + _tx.scriptDataLength], (bytes));
            index += 1;

            // Init the new inputs struct based on the input count.
            _tx.inputs = new Input[](_tx.inputsCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.inputsCount; i++) {
                _tx.inputs[i] = decompressInput(data[index:]);
                index += _tx.inputs[i]._bytesize;
            }

            // Init the new outputs struct based on the output count.
            _tx.outputs = new Output[](_tx.outputsCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.outputsCount; i++) {
                _tx.outputs[i] = decompressOutput(data[index:]);
                index += _tx.outputs[i]._bytesize;
            }

            // Init the new outputs struct based on the output count.
            _tx.witnesses = new Witness[](_tx.witnessesCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.witnessesCount; i++) {
                _tx.witnesses[i] = decompressWitness(data[index:]);
                index += _tx.witnesses[i]._bytesize;
            }
        }

        // Contract.
        if (_tx.kind == TransactionKind.Create) {
            // Bytecode length.
            _tx.bytecodeLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Script data length.
            _tx.bytecodeWitnessIndex = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Script data length.
            _tx.staticContractsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The number of inputs in the transaction.
            _tx.inputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The number of outputs in the transaciton.
            _tx.outputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // The number of witnesses in the transaction.
            _tx.salt = bytes32(abi.decode(data[index:index + 32], (bytes32)));
            index += 1;

            // Setup new static contracts.
            _tx.staticContracts = new bytes32[](_tx.staticContractsCount);

            // Decode into array.
            for (uint8 i = 0; i < _tx.staticContractsCount; i++) {
                _tx.staticContracts[i] = bytes32(abi.decode(data[index:index + 32], (bytes32)));
                index += 32;
            }

            // Init the new inputs struct based on the input count.
            _tx.inputs = new Input[](_tx.inputsCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.inputsCount; i++) {
                _tx.inputs[i] = decompressInput(data[index:]);
                index += _tx.inputs[i]._bytesize;
            }

            // Init the new outputs struct based on the output count.
            _tx.outputs = new Output[](_tx.outputsCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.outputsCount; i++) {
                _tx.outputs[i] = decompressOutput(data[index:]);
                index += _tx.outputs[i]._bytesize;
            }

            // Init the new outputs struct based on the output count.
            _tx.witnesses = new Witness[](_tx.witnessesCount);

            // Decompress each input into array.
            for (uint8 i = 0; i < _tx.witnessesCount; i++) {
                _tx.witnesses[i] = decompressWitness(data[index:]);
                index += _tx.witnesses[i]._bytesize;
            }
        }
    }
}