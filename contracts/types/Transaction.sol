// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Input.sol";
import "./Output.sol";
import "./Witness.sol";
import "./TXOPointer.sol";
import "./DigestPointer.sol";

/// @notice The two kinds of transactions in Fuel.
enum TransactionKind {
    // Used for transactions with scripts.
    Script,
    // Used for creating Fuel smart-contracts.
    Create,
    // A placeholder for checking invalid types
    END
}

/// @notice An expanded combo structure for: TransactionScript and TransactionCreate.
struct Transaction {
    // Transaction kind.
    TransactionKind kind;
    // Gas price for transaction.
    uint64 gasPrice;
    // Gas limit for transaction.
    uint64 gasLimit;
    // Block until which tx cannot be included.
    uint64 maturity;
    // CreateOnly: length of the script.
    uint16 scriptLength;
    // Script to execute.
    bytes script;
    // CreateOnly: Script data length.
    uint16 scriptDataLength;
    // Script input data (parameters).
    bytes scriptData;
    // CreateOnly: length of the script.
    uint8 inputsCount;
    // CreateOnly: length of the script.
    uint8 outputsCount;
    // CreateOnly: length of the script.
    uint8 witnessesCount;
    // receiptsRoot: Merkle root of receipts.
    bytes32 receiptsRoot;
    // List of inputs.
    Input[] inputs;
    // List of outputs.
    Output[] outputs;
    // List of witnesses.
    Witness[] witnesses;
    // CreateOnly: Contract bytecode length, in instructions.
    uint16 bytecodeLength;
    // CreateOnly: Witness index of contract bytecode to create.
    uint8 bytecodeWitnessIndex;
    // CreateOnly: Number of static contracts.
    uint8 staticContractsCount;
    // CreateOnly: Salt.
    bytes32 salt;
    // CreateOnly: List of static contracts (pointers for compressed transaction format)
    bytes32[] staticContracts;
    TXOPointer[] staticContractsPointers;
}
