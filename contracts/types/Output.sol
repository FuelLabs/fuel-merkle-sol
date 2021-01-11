// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

enum OutputType {
    // Simple transfer UTXO, no special conditions
    Transfer,
    // Burn coins to enable withdrawing them
    Withdraw,
    // An HTLC UTXO
    HTLC,
    // A non-send; used for posting data
    Return
}

/// @notice Transaction output
struct Output {
    // Output type
    OutputType t;
    ////////////
    // Output //
    ////////////
    // Token ID
    uint32 tokenId;
    // Amount of tokens
    uint256 amount;
    // Recipient
    // TODO some logic to convert index to address always
    address owner;
    //////////
    // HTLC //
    //////////
    // Hashlock digest
    bytes32 digest;
    // Timelock expiry (Ethereum block number)
    uint32 expiry;
    // Return owner if timelock expires
    // TODO some logic to convert index to address always
    address returnOwner;
    ////////////
    // Return //
    ////////////
    // Raw data byte array
    bytes1[] data;
}

/// @notice A rollup state element: a UTXO. The UTXO ID is the hash of its fields.
struct UTXO {
    // Transaction ID (witnesses sign over this value)
    bytes32 transactionId;
    // Output index in list of outputs
    uint8 outputIndex;
    OutputType outputType;
    address owner;
    uint256 amount;
    uint32 token;
    bytes32 digest;
    uint32 expiry;
    address returnOwner;
}

/// @notice Output helper functions
library OutputHelper {
    /////////////
    // Methods //
    /////////////

    /// @notice Try to parse output bytes.
    function parseOutput(bytes calldata s)
        internal
        pure
        returns (Output memory, bool)
    {
        // TODO
    }

    /// @notice Get size of an output object.
    /// @return Size of output in bytes.
    function outputSize(Output memory output) internal pure returns (uint8) {
        // TODO double check these sizes
        if (output.t == OutputType.Transfer) {
            return 1;
        } else if (output.t == OutputType.Withdraw) {
            return 1;
        } else if (output.t == OutputType.HTLC) {
            return 1;
        } else if (output.t == OutputType.Return) {
            return 1;
        }
        // avoid infinite loops
        // TODO can we remove this?
        return 20;
    }
}
