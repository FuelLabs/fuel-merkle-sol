//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;

import "../types/Transaction.sol";

library TransactionLib {

    ///////////////
    // Constants //
    ///////////////

    /// @dev Minimum transaction size in bytes.
    uint256 constant internal TRANSACTION_SIZE_MIN = 44;

    /// @dev Maximum transaction size in bytes.
    uint256 constant internal TRANSACTION_SIZE_MAX = 21000;

    /// @dev Empty leaf hash default value.
    bytes32 constant internal EMPTY_LEAF_HASH = bytes32(0);

    /// @dev  Gas charged per byte of the transaction.
    uint64 constant internal GAS_PER_BYTE = 1;

    /// @dev Maximum gas per transaction.
    uint64 constant internal MAX_GAS_PER_TX = 100000;

    /// @dev Maximum number of inputs.
    uint64 constant internal MAX_INPUTS = 16;

    /// @dev Maximum number of outputs.
    uint64 constant internal MAX_OUTPUTS = 16;

    /// @dev Maximum length of predicate, in instructions.
    uint64 constant internal MAX_PREDICATE_LENGTH = 2400;
    
    /// @dev Maximum length of predicate data, in bytes.
    uint64 constant internal MAX_PREDICATE_DATA_LENGTH = 2400; 

    /// @dev Maximum length of script, in instructions.
    uint64 constant internal MAX_SCRIPT_LENGTH = 2400;

    /// @dev Maximum length of script, in instructions.
    uint64 constant internal MAX_CONTRACT_LENGTH = 21000;

    /// @dev Maximum length of script data, in bytes.
    uint64 constant internal MAX_SCRIPT_DATA_LENGTH = 2400;

    /// @dev Maximum number of static contracts.
    uint64 constant internal MAX_STATIC_CONTRACTS = 256;

    /// @dev  Max witnesses.
    uint64 constant internal MAX_WITNESSES = 16;

    /////////////
    // Methods //
    /////////////

    /// @notice Decompress a single input.
    /// @param data The input data in compressed bytes.
    /// @dev Note, we arn't checking for overflows yet.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/compressed_tx_format.md#inputcoin.
    /// @return _input The input to return.
    function decompressInput(bytes calldata data) internal pure returns (Input memory _input) {
        // Tracking index.
        uint16 index = 0;

        // Decompress the transaction kind.
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
    /// @dev Note, we arn't checking for overflows yet.
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
            _output.toPointer.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
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
            _output.toPointer.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
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
            _output.toPointer.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
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
            _output.toPointer.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // The amount of the output.
            _output.amount = uint64(abi.decode(data[index:index + 8], (bytes8)));
            index += 8;

            // The TXO pointer block height.
            _output.colorIndex.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.colorIndex.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Specify the bytesize of this output.
            _output._bytesize = index;
            
            // Stop and return.
            return _output;
        }

        // Handle the ContractCreated.
        if (_output.kind == OutputKind.ContractCreated) {
            // The TXO pointer block height.
            _output.contractPointer.blockHeight = uint32(abi.decode(data[index:index + 4], (bytes4)));
            index += 4;

            // The TXO pointer block height.
            _output.contractPointer.index = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

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

    /// @notice Serialize Input struct.
    /// @param input The Input struct.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/tx_format.md.
    /// @return data The serialized data.
    function serializeInput(Input memory input) internal pure returns (bytes memory data) {
        // Encode the type.
        data = abi.encodePacked(uint8(input.kind));

        // Handle the Input coin case.
        if (input.kind == InputKind.Coin) {
            data = abi.encodePacked(
                data,
                input.utxoID,
                input.owner,
                input.amount,
                input.color,
                input.witnessIndex,
                input.maturity,
                input.predicateLength,
                input.predicateDataLength,
                input.predicate,
                input.predicateData
            );
        }

        // Handle the Contract case.
        if (input.kind == InputKind.Contract) {
            // Serialize the struct into a single bytes data.
            data = abi.encodePacked(
                data,
                input.utxoID,
                input.balanceRoot,
                input.stateRoot,
                input.contractID
            );
        }
    }

    /// @notice Serialize a single output.
    /// @param output The output struct.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/tx_format.md#output.
    /// @return data The serialized bytes data.
    function serializeOutput(Output memory output) internal pure returns (bytes memory data) {
        // Encode the type.
        data = abi.encodePacked(uint8(output.kind));

        // Handle the Coin case.
        if (output.kind == OutputKind.Coin) {
            data = abi.encodePacked(
                data,
                output.to,
                output.amount,
                output.color
            );
        }

        // Handle the Contract case.
        if (output.kind == OutputKind.Contract) {
            data = abi.encodePacked(
                data,
                output.inputIndex,
                output.balanceRoot,
                output.stateRoot
            );
        }

        // Handle the Withdrawal case.
        if (output.kind == OutputKind.Withdrawal) {
            data = abi.encodePacked(
                data,
                output.to,
                output.amount,
                output.color
            );
        }

        // Handle the Change case.
        if (output.kind == OutputKind.Change) {
            data = abi.encodePacked(
                data,
                output.to,
                output.amount,
                output.color
            );
        }

        // Handle the Variable case.
        if (output.kind == OutputKind.Variable) {
            data = abi.encodePacked(
                data,
                output.to,
                output.amount,
                output.color
            );
        }

        // Handle the ContractCreated case.
        if (output.kind == OutputKind.ContractCreated) {
            data = abi.encodePacked(
                data,
                output.contractID
            );
        }
    }

    /// @notice Serialize a single witness.
    /// @param witness The witness struct.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/tx_format.md#witness.
    /// @return data The serialized bytes data.
    function serializeWitness(Witness memory witness) internal pure returns (bytes memory data) {
        // Encode the witness.
        data = abi.encodePacked(
            witness.dataLength,
            witness.data
        );
    }

    /// @notice Serialize a Transaction into a bytes form.
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/tx_format.md
    /// @param _tx The Transaction struct to be serialized.
    /// @return data The serialized form of a transaction.
    function serialize(Transaction memory _tx) internal pure returns (bytes memory data) {
        // Encode the type.
        data = abi.encodePacked(uint8(_tx.kind));

        // Script.
        if (_tx.kind == TransactionKind.Script) {
            // The initial data before the inputs etc.
            data = abi.encodePacked(
                data,
                _tx.gasPrice,
                _tx.gasLimit,
                _tx.maturity,
                _tx.scriptLength,
                _tx.scriptDataLength,
                _tx.inputsCount,
                _tx.outputsCount,
                _tx.witnessesCount,
                _tx.script,
                _tx.scriptData
            );
        }

        // Create.
        if (_tx.kind == TransactionKind.Create) {
            // The initial data before the inputs etc.
            data = abi.encodePacked(
                data,
                _tx.gasPrice,
                _tx.gasLimit,
                _tx.maturity,
                _tx.bytecodeLength,
                _tx.bytecodeWitnessIndex,
                _tx.staticContractsCount,
                _tx.inputsCount,
                _tx.outputsCount,
                _tx.witnessesCount,
                _tx.salt,
                _tx.staticContracts
            );
        }

        // Now we serialize the inputs, outputs and witnesses.
        // Serialize inputs.
        for (uint i = 0; i < _tx.inputs.length; i++) {
            data = abi.encodePacked(
                data,
                serializeInput(_tx.inputs[i])
            );
        }

        // Serialize outputs.
        for (uint i = 0; i < _tx.outputs.length; i++) {
            data = abi.encodePacked(
                data,
                serializeOutput(_tx.outputs[i])
            );
        }

        // Serialize witnesses.
        for (uint i = 0; i < _tx.witnesses.length; i++) {
            data = abi.encodePacked(
                data,
                serializeWitness(_tx.witnesses[i])
            );
        }
    }

    /// @notice Transaction id.
    /// @param _tx The transaction to be serialized and hashed.
    /// @return id The computed transaction identifier.
    /// @dev We haven't completed the zero out of specific fields yet.
    function computeTransactionId(Transaction memory _tx) internal pure returns (bytes32 id) {
        // TODO: Should be Zero out specific fields, then hash.
        return sha256(serialize(_tx));
    }

    /// @notice Decompress bytes into a Transaction object.
    /// @param data The compressed transaction data.
    /// @dev Note, we arn't checking for overflows yet.
    /// @return _tx The uncompressed transaction data.
    function decompress(bytes calldata data) internal pure returns (Transaction memory _tx, string memory error) {
        // Tracking index.
        uint16 index = 0;

        // The transaciton kind.
        uint8 kind = uint8(abi.decode(data[index:index + 1], (bytes1)));

        // Check invalid kind.
        if (kind > 1) {
            return (_tx, "invalid-kind");
        }

        // Decode the transaction kind.;
        _tx.kind = TransactionKind(kind);
        index += 1;

        // Decode the gas price.
        _tx.gasPrice = uint64(abi.decode(data[index:index + 8], (bytes8)));
        index += 8;

        // Check invalid kind.
        if (_tx.gasPrice > MAX_GAS_PER_TX) {
            return (_tx, "gas-price-overflow");
        }

        // Decode the gas limit.
        _tx.gasLimit = uint64(abi.decode(data[index:index + 8], (bytes8)));
        index += 8;

        // Check invalid gas limit.
        if (_tx.gasLimit > MAX_GAS_PER_TX) {
            return (_tx, "gas-limit-overflow");
        }

        // Decode the maturity.
        _tx.maturity = uint32(abi.decode(data[index:index + 4], (bytes4)));
        index += 4;

        // Script.
        if (_tx.kind == TransactionKind.Script) {
            // Script length.
            _tx.scriptLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Check invalid gas limit.
            if (_tx.scriptLength > MAX_SCRIPT_LENGTH) {
                return (_tx, "script-length-overflow");
            }

            // Script data length.
            _tx.scriptDataLength = uint16(abi.decode(data[index:index + 2], (bytes2)));
            index += 2;

            // Check invalid gas limit.
            if (_tx.scriptDataLength > MAX_SCRIPT_DATA_LENGTH) {
                return (_tx, "script-data-length-overflow");
            }

            // The number of inputs in the transaction.
            _tx.inputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Check invalid gas limit.
            if (_tx.inputsCount > MAX_INPUTS) {
                return (_tx, "inputs-count-overflow");
            }

            // The number of outputs in the transaciton.
            _tx.outputsCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Check invalid gas limit.
            if (_tx.outputsCount > MAX_OUTPUTS) {
                return (_tx, "outputs-count-overflow");
            }

            // The number of witnesses in the transaction.
            _tx.witnessesCount = uint8(abi.decode(data[index:index + 1], (bytes1)));
            index += 1;

            // Check invalid gas limit.
            if (_tx.witnessesCount > MAX_WITNESSES) {
                return (_tx, "witnesses-count-overflow");
            }

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