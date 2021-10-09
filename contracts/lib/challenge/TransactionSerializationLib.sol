// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../../types/Transaction.sol";
import "../Transaction.sol";

library TransactionSerializationLib {
    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a TXO pointer struct
    /// @param pointer : The TXO pointer
    function serializeTXOPointer(TXOPointer memory pointer)
        internal
        pure
        returns (bytes memory data)
    {
        return
            abi.encodePacked(
                uint64(pointer.blockHeight),
                uint64(pointer.txIndex),
                uint64(pointer.outputIndex)
            );
    }

    /// @notice Serialize a Digest pointer struct
    /// @param pointer : The Digest pointer
    function serializeDigestPointer(DigestPointer memory pointer)
        internal
        pure
        returns (bytes memory data)
    {
        return abi.encodePacked(uint64(pointer.blockHeight), uint64(pointer.index));
    }

    /// @notice Zero pad bytes to next multiple of 8
    /// @param b : The bytes to pad
    /// @return Padded bytes
    function padBytes(bytes memory b) public pure returns (bytes memory) {
        // If/else chain looks unwieldy, but Solidity has no support for variable-sized byte array literals (e.g. bytesN(0)) at the time of writing
        // Whilst a loop is possible, the cost of abi.encodePacked scales with b, so multiple invocations are to be avoided.
        uint256 padLength = 8 - (b.length % 8);
        if (padLength == 7) {
            b = abi.encodePacked(b, bytes7(0));
        } else if (padLength == 6) {
            b = abi.encodePacked(b, bytes6(0));
        } else if (padLength == 5) {
            b = abi.encodePacked(b, bytes5(0));
        } else if (padLength == 4) {
            b = abi.encodePacked(b, bytes4(0));
        } else if (padLength == 3) {
            b = abi.encodePacked(b, bytes3(0));
        } else if (padLength == 2) {
            b = abi.encodePacked(b, bytes2(0));
        } else if (padLength == 1) {
            b = abi.encodePacked(b, bytes1(0));
        }
        return b;
    }

    /// @notice Serialize Input struct.
    /// @param input The Input struct.
    /// @param compressed Whether the input to serialize is compressed or not
    /// @return data The serialized data.
    function serializeInput(
        Input memory input,
        bool compressed,
        uint256 numWitnesses
    ) internal pure returns (bytes memory data) {
        // Perform general input checks
        require(input.kind < InputKind.END, "Invalid input type");

        // Encode the type.
        data = abi.encodePacked(uint64(input.kind));

        // Handle the Input coin case.
        if (input.kind == InputKind.Coin) {
            // Perform input coin checks:
            require(input.witnessIndex < numWitnesses, "Witness index too high");
            require(
                input.predicateLength <= TransactionLib.MAX_PREDICATE_LENGTH,
                "Predicate too long"
            );
            require(
                input.predicateDataLength <= TransactionLib.MAX_PREDICATE_DATA_LENGTH,
                "predicateData too long"
            );

            require(input.predicate.length == input.predicateLength, "Incorrect predicate length");
            require(
                input.predicateData.length == input.predicateDataLength,
                "Incorrect predicateData length"
            );

            // If compressed, serialize pointer
            if (compressed) {
                data = abi.encodePacked(data, serializeTXOPointer(input.pointer));
            }
            // Otherwise, serialize full ID with owner, color, and amount
            else {
                data = abi.encodePacked(data, input.utxoID, input.owner, input.amount, input.color);
            }

            // Serialize the remaining properties (which are common to compressed and uncompressed transactions)
            data = abi.encodePacked(
                data,
                uint64(input.witnessIndex),
                uint64(input.maturity),
                uint64(input.predicateLength),
                uint64(input.predicateDataLength),
                padBytes(input.predicate),
                padBytes(input.predicateData)
            );
        }

        // Handle the Contract case.
        if (input.kind == InputKind.Contract) {
            if (compressed) {
                // Serialize the struct into a single bytes data.
                data = abi.encodePacked(data, serializeTXOPointer(input.pointer));
            } else {
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
    }

    /// @notice Serialize a single output.
    /// @param output The output struct.
    /// @param compressed Whether the output to serialize is compressed or not
    /// @return data The serialized bytes data.
    function serializeOutput(Output memory output, bool compressed)
        internal
        pure
        returns (bytes memory data)
    {
        // Perform generic output checks:
        require(output.kind < OutputKind.END, "Invalid output kind");

        // Encode the type.
        data = abi.encodePacked(uint64(output.kind));

        // Handle the Contract case
        if (output.kind == OutputKind.Contract) {
            // if output.InputIndex out of range of inputs, transaction will revert earlier (in serializeTransaction)

            // Serialize the input index (common to  compressed and uncompressed transactions)
            data = abi.encodePacked(data, uint64(output.inputIndex));

            // If tx is uncompressed, also serialzie balance and state roots
            if (!compressed) {
                data = abi.encodePacked(data, output.balanceRoot, output.stateRoot);
            }
        }

        // Handle the Coin / Withdrawal / Change / Variable cases.
        if (
            (output.kind == OutputKind.Coin) ||
            (output.kind == OutputKind.Withdrawal) ||
            (output.kind == OutputKind.Change) ||
            (output.kind == OutputKind.Variable)
        ) {
            // For compressed transactions, "to" and "color" are pointers
            if (compressed) {
                data = abi.encodePacked(
                    data,
                    serializeDigestPointer(output.toPointer),
                    output.amount,
                    serializeDigestPointer(output.colorPointer)
                );
            } else {
                data = abi.encodePacked(data, output.to, output.amount, output.color);
            }
        }

        // Handle the ContractCreated case.
        if (output.kind == OutputKind.ContractCreated) {
            if (compressed) {
                data = abi.encodePacked(data, serializeDigestPointer(output.contractIDPointer));
            } else {
                data = abi.encodePacked(data, output.contractID);
            }
        }
    }

    /// @notice Serialize a single witness.
    /// @param witness The witness struct.
    /// @return data The serialized bytes data.
    function serializeWitness(Witness memory witness) internal pure returns (bytes memory data) {
        require(witness.data.length == witness.dataLength, "Incorect witness length");
        // Encode the witness.
        data = abi.encodePacked(uint64(witness.dataLength), padBytes(witness.data));
    }

    /// @notice Serialize a Transaction into a bytes form.
    /// @dev The transaction must be well formed according to the rules specified in:
    /// @dev https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/tx_format.md
    /// @param _tx The Transaction struct to be serialized.
    /// @param compressed Whether the transaction to serialize is compressed or not
    /// @return data The serialized form of a transaction.
    function serializeTransaction(Transaction memory _tx, bool compressed)
        external
        pure
        returns (bytes memory data)
    {
        // Perform general transaction checks
        require(_tx.kind < TransactionKind.END, "Invalid transaction type");
        require(_tx.gasLimit <= TransactionLib.MAX_GAS_PER_TX, "Gas limit too high");
        require(_tx.inputsCount <= TransactionLib.MAX_INPUTS, "Too many inputs");
        require(_tx.outputsCount <= TransactionLib.MAX_OUTPUTS, "Too many outputs");
        require(_tx.witnessesCount <= TransactionLib.MAX_WITNESSES, "Too many witnesses");
        require(_tx.inputs.length == _tx.inputsCount, "inputs length mismatch");
        require(_tx.outputs.length == _tx.outputsCount, "outputs length mismatch");
        require(_tx.witnesses.length == _tx.witnessesCount, "witnesses length mismatch");

        // Encode the type.
        data = abi.encodePacked(uint64(_tx.kind));

        // Script.
        if (_tx.kind == TransactionKind.Script) {
            // Perform script-specific transaction checks

            //If tx is script, invalid if any output is of type OutputType.ContractCreated
            for (uint256 i = 0; i < _tx.outputsCount; i += 1) {
                require(
                    _tx.outputs[i].kind != OutputKind.ContractCreated,
                    "Script cannot create contract"
                );

                // Invalid if an output Contract's inputIndex does not point to a Contract type in the input set
                if (_tx.outputs[i].kind == OutputKind.Contract) {
                    require(
                        _tx.inputs[_tx.outputs[i].inputIndex].kind == InputKind.Contract,
                        "Output contract has no input"
                    );
                }
            }

            require(_tx.scriptLength <= TransactionLib.MAX_SCRIPT_LENGTH, "Script too long");
            require(
                _tx.scriptDataLength <= TransactionLib.MAX_SCRIPT_DATA_LENGTH,
                "scriptData too long"
            );

            require(_tx.script.length == _tx.scriptLength, "Incorrect script length");
            require(_tx.scriptData.length == _tx.scriptDataLength, "Incorrect scriptData length");

            // The initial data before the inputs etc.
            data = abi.encodePacked(
                data,
                _tx.gasPrice,
                _tx.gasLimit,
                _tx.maturity,
                uint64(_tx.scriptLength),
                uint64(_tx.scriptDataLength),
                uint64(_tx.inputsCount),
                uint64(_tx.outputsCount),
                uint64(_tx.witnessesCount)
            );

            // Uncompressed transactions have merkle root of receipts:
            if (!compressed) {
                data = abi.encodePacked(data, _tx.receiptsRoot);
            }

            data = abi.encodePacked(data, padBytes(_tx.script), padBytes(_tx.scriptData));
        }

        // Create.
        if (_tx.kind == TransactionKind.Create) {
            // Perform Create-specific transaction checks

            //If tx is Create, invalid if:
            for (uint256 i = 0; i < _tx.inputsCount; i += 1) {
                // any input is of type Contract:
                require(
                    _tx.inputs[i].kind != InputKind.Contract,
                    "Create cant have input contract"
                );
            }

            bool contractCreatedOutput = false;
            bool zeroColorOutputChange = false;
            for (uint256 i = 0; i < _tx.outputsCount; i += 1) {
                // Invalid if any output is of type Contract or Variable
                require(
                    _tx.outputs[i].kind != OutputKind.Contract,
                    "Create cant have output contract"
                );
                require(
                    _tx.outputs[i].kind != OutputKind.Variable,
                    "Create cant have output variable"
                );

                // Invalid if more than one output is of type OutputType.Change
                // or, if any output is of type OutputKind.Change with non-zero color
                if (_tx.outputs[i].kind == OutputKind.Change) {
                    require(_tx.outputs[i].color == 0, "Non zero-color change outputs");
                    require(zeroColorOutputChange == false, "Multiple change outputs");
                    zeroColorOutputChange = true;
                }

                // Invalid if more than one output is of type OutputType.ContractCreated
                if (_tx.outputs[i].kind == OutputKind.ContractCreated) {
                    require(contractCreatedOutput == false, "Multiple contractCreate outputs");
                    contractCreatedOutput = true;
                }
            }

            require(contractCreatedOutput == true, "Must have contractCreate output");

            require(
                _tx.bytecodeLength * 4 <= TransactionLib.MAX_CONTRACT_LENGTH,
                "bytecode too long"
            ); // Check for overflow ?

            require(_tx.bytecodeWitnessIndex < _tx.witnessesCount, "Witness index too high");

            require(
                _tx.witnesses[_tx.bytecodeWitnessIndex].dataLength == _tx.bytecodeLength * 4,
                "wrong bytecode data length"
            );
            require(
                _tx.staticContractsCount <= TransactionLib.MAX_STATIC_CONTRACTS,
                "Too many static contracts"
            );
            require(
                _tx.staticContractsCount == _tx.staticContracts.length,
                "staticContracts length mismatch"
            );

            if (!compressed) {
                // Check static contract IDs are in ascending order
                uint256 size = 0;
                for (uint256 i = 0; i < _tx.staticContracts.length; i += 1) {
                    require(uint256(_tx.staticContracts[i]) > size, "staticContracts not ordered");
                    size = uint256(_tx.staticContracts[i]);
                }
            }

            // The initial data before the inputs etc.
            data = abi.encodePacked(
                data,
                _tx.gasPrice,
                _tx.gasLimit,
                _tx.maturity,
                uint64(_tx.bytecodeLength),
                uint64(_tx.bytecodeWitnessIndex),
                uint64(_tx.staticContractsCount),
                uint64(_tx.inputsCount),
                uint64(_tx.outputsCount),
                uint64(_tx.witnessesCount),
                _tx.salt
            );
        }

        // Serialize staticContracts
        if (compressed) {
            data = abi.encodePacked(data, _tx.staticContracts);
        } else {
            for (uint256 i = 0; i < _tx.staticContractsPointers.length; i += 1) {
                data = abi.encodePacked(data, serializeTXOPointer(_tx.staticContractsPointers[i]));
            }
        }

        // Serialize inputs.
        for (uint256 i = 0; i < _tx.inputs.length; i += 1) {
            data = abi.encodePacked(
                data,
                serializeInput(_tx.inputs[i], compressed, _tx.witnessesCount)
            );
        }

        // Serialize outputs.
        for (uint256 i = 0; i < _tx.outputs.length; i += 1) {
            data = abi.encodePacked(data, serializeOutput(_tx.outputs[i], compressed));
        }

        // Serialize witnesses.
        for (uint256 i = 0; i < _tx.witnesses.length; i += 1) {
            data = abi.encodePacked(data, serializeWitness(_tx.witnesses[i]));
        }
    }
}
