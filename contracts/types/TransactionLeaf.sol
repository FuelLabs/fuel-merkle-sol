// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../TransactionHandler.sol";
import "./Input.sol";
import "./Metadata.sol";
import "./Output.sol";
import "./Witness.sol";

/// @notice Leaf of transaction Merkle tree.
struct TransactionLeaf {
    // List of metadata, one per input
    Metadata[] metadata;
    // List of witnesses
    Witness[] witnesses;
    // List of inputs
    Input[] inputs;
    // List of outputs
    Output[] outputs;
}

/// @title Transaction leaf helper functions
library TransactionLeafHelper {
    /////////////
    // Methods //
    /////////////

    /// @notice Try to parse transaction leaf bytes.
    function parseTransactionLeaf(bytes calldata s)
        internal
        pure
        returns (TransactionLeaf memory, bool)
    {
        // TODO change the client-size encoding
        // NOTE: the transaction leaf is now assumed to be serialized with the length of each field at the beginning
        // NOTE: lengths are now the number of elements, not the number of bytes

        uint8 metadataLength = uint8(abi.decode(s[0:1], (bytes1)));
        uint8 witnessesLength = uint8(abi.decode(s[1:2], (bytes1)));
        uint8 inputsLength = uint8(abi.decode(s[2:3], (bytes1)));
        uint8 outputsLength = uint8(abi.decode(s[3:4], (bytes1)));

        // Create transaction leaf as empty just to have something to return
        TransactionLeaf memory transactionLeaf =
            TransactionLeaf(
                new Metadata[](0),
                new Witness[](0),
                new Input[](0),
                new Output[](0)
            );

        if (
            s.length < TransactionHandler.TRANSACTION_SIZE_MIN ||
            s.length > TransactionHandler.TRANSACTION_SIZE_MAX
        ) return (transactionLeaf, false);
        if (metadataLength > TransactionHandler.INPUTS_MAX)
            return (transactionLeaf, false);
        if (witnessesLength > TransactionHandler.INPUTS_MAX)
            return (transactionLeaf, false);
        if (inputsLength > TransactionHandler.INPUTS_MAX)
            return (transactionLeaf, false);
        if (outputsLength > TransactionHandler.OUTPUTS_MAX)
            return (transactionLeaf, false);

        transactionLeaf = TransactionLeaf(
            new Metadata[](metadataLength),
            new Witness[](witnessesLength),
            new Input[](inputsLength),
            new Output[](outputsLength)
        );

        bool success;
        // Start offset at 4 bytes since we parsed the lengths
        uint256 offset = 4;
        uint256 bytesUsed;

        (bytesUsed, success) = _parseLeafMetadata(
            transactionLeaf,
            metadataLength,
            s[offset:]
        );
        if (!success) {
            return (transactionLeaf, false);
        }
        offset += bytesUsed;

        (bytesUsed, success) = _parseLeafMetadata(
            transactionLeaf,
            metadataLength,
            s[offset:]
        );
        offset += bytesUsed;
        if (!success) {
            return (transactionLeaf, false);
        }
        if (offset >= s.length - 1) {
            return (transactionLeaf, false);
        }

        (bytesUsed, success) = _parseLeafWitnesses(
            transactionLeaf,
            witnessesLength,
            s[offset:]
        );
        offset += bytesUsed;
        if (!success) {
            return (transactionLeaf, false);
        }
        if (offset >= s.length - 1) {
            return (transactionLeaf, false);
        }

        (bytesUsed, success) = _parseLeafInputs(
            transactionLeaf,
            witnessesLength,
            s[offset:]
        );
        offset += bytesUsed;
        if (!success) {
            return (transactionLeaf, false);
        }
        if (offset >= s.length - 1) {
            return (transactionLeaf, false);
        }

        (bytesUsed, success) = _parseLeafOutputs(
            transactionLeaf,
            witnessesLength,
            s[offset:]
        );
        offset += bytesUsed;
        if (!success) {
            return (transactionLeaf, false);
        }
        if (offset != s.length - 1) {
            return (transactionLeaf, false);
        }

        return (transactionLeaf, true);
    }

    function _parseLeafMetadata(
        TransactionLeaf memory leaf,
        uint8 length,
        bytes calldata s
    ) private pure returns (uint256, bool) {
        uint256 offset = 0;

        for (uint256 i = 0; i < length; i++) {
            bool success;
            uint256 bytesUsed;

            (leaf.metadata[i], bytesUsed, success) = MetadataHelper
                .parseMetadata(s[offset:]);
            offset += bytesUsed;

            if (!success) {
                return (offset, false);
            }
            if (offset >= s.length - 1) {
                return (offset, false);
            }
        }

        return (offset, true);
    }

    function _parseLeafWitnesses(
        TransactionLeaf memory leaf,
        uint8 length,
        bytes calldata s
    ) private pure returns (uint256, bool) {
        uint256 offset = 0;

        for (uint256 i = 0; i < length; i++) {
            bool success;
            uint256 bytesUsed;

            (leaf.witnesses[i], bytesUsed, success) = WitnessHelper
                .parseWitness(s[offset:]);
            offset += bytesUsed;

            if (!success) {
                return (offset, false);
            }
            if (offset >= s.length - 1) {
                return (offset, false);
            }
        }

        return (offset, true);
    }

    function _parseLeafInputs(
        TransactionLeaf memory leaf,
        uint8 length,
        bytes calldata s
    ) private pure returns (uint256, bool) {
        uint256 offset = 0;

        for (uint256 i = 0; i < length; i++) {
            bool success;
            uint256 bytesUsed;

            (leaf.inputs[i], bytesUsed, success) = InputHelper
                .parseInput(s[offset:]);
            offset += bytesUsed;

            if (!success) {
                return (offset, false);
            }
            if (offset >= s.length - 1) {
                return (offset, false);
            }
        }

        return (offset, true);
    }

    function _parseLeafOutputs(
        TransactionLeaf memory leaf,
        uint8 length,
        bytes calldata s
    ) private pure returns (uint256, bool) {
        uint256 offset = 0;

        for (uint256 i = 0; i < length; i++) {
            bool success;
            uint256 bytesUsed;

            (leaf.outputs[i], bytesUsed, success) = OutputHelper
                .parseOutput(s[offset:]);
            offset += bytesUsed;

            if (!success) {
                return (offset, false);
            }
            if (offset >= s.length - 1) {
                return (offset, false);
            }
        }

        return (offset, true);
    }
}
