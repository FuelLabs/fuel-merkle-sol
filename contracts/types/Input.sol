// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

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
        returns (Input memory, bool)
    {
        // TODO
    }

    /// @notice Get size of an input object.
    /// @return Size of input in bytes.
    function inputSize(Input memory input) internal pure returns (uint8) {
        if (input.t == InputType.HTLC) {
            return 34;
        } else if (input.t == InputType.Deposit) {
            return 22;
        }
        return 2;
    }
}
