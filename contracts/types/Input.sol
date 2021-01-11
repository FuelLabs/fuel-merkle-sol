// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../TransactionHandler.sol";

enum InputType {
    // Simple transfer UTXO, no special conditions
    Transfer,
    // Spending a deposit from Ethereum
    Deposit,
    // Spending an HTLC UTXO
    HTLC,
    // Spending a Root UTXO (i.e. collected fees)
    Root
}

/// @notice Transaction input
struct Input {
    // Input type
    InputType t;
    // Index of witness that authorizes spending this input
    uint8 witnessReference;
    // Recipient address
    address owner;
    // Preimage to hashlock
    bytes32 preimage;
}

/// @notice Input helper functions
library InputHelper {
    /////////////
    // Methods //
    /////////////

    /// @notice Try to parse input bytes.
    function parseInput(bytes calldata s)
        internal
        pure
        returns (
            Input memory,
            uint256,
            bool
        )
    {
        Input memory input;
        uint256 bytesUsed;

        // Type
        uint8 typeRaw = uint8(abi.decode(s[0:1], (bytes1)));
        if (typeRaw > uint8(InputType.Root)) return (input, bytesUsed, false);
        input.t = InputType(typeRaw);

        bytesUsed = _inputSize(input);
        if (s.length < bytesUsed) {
            return (input, bytesUsed, false);
        }

        if (input.t == InputType.Transfer || input.t == InputType.Root) {
            // Transfer or Root
            input.witnessReference = uint8(abi.decode(s[1:2], (bytes1)));
        } else if (input.t == InputType.Deposit) {
            // Deposit
            input.witnessReference = uint8(abi.decode(s[1:2], (bytes1)));
            input.owner = address(abi.decode(s[2:22], (bytes20)));
        } else if (input.t == InputType.HTLC) {
            // HTLC
            input.witnessReference = uint8(abi.decode(s[1:2], (bytes1)));
            input.preimage = bytes32(abi.decode(s[2:34], (bytes32)));
        }

        if (!_sanitizeInput(input)) return (input, bytesUsed, false);

        return (input, bytesUsed, true);
    }

    /// @notice Get size of an input object.
    /// @return Size of input in bytes.
    function _inputSize(Input memory input) private pure returns (uint8) {
        if (input.t == InputType.Transfer || input.t == InputType.Root) {
            return 2;
        } else if (input.t == InputType.Deposit) {
            return 22;
        } else if (input.t == InputType.HTLC) {
            return 34;
        }
        revert();
    }

    function _sanitizeInput(Input memory input) private pure returns (bool) {
        if (input.witnessReference >= TransactionHandler.INPUTS_MAX)
            return false;

        return true;
    }
}
