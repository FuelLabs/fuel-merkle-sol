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
    address tokenAddress;
    // Amount of tokens
    uint256 amount;
    // Recipient (if ID is 0, use address)
    uint32 ownerId;
    address ownerAddress;
    //////////
    // HTLC //
    //////////
    // Hashlock digest
    bytes32 digest;
    // Timelock expiry (Ethereum block number)
    uint32 expiry;
    // Return owner if timelock expires (if ID is 0, use address)
    uint32 returnOwnerId;
    address returnOwnerAddress;
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
        returns (
            Output memory,
            uint256,
            bool
        )
    {
        // TODO
        Output memory output;
        uint256 bytesUsed;
    }

    function _sanitizeOutput(Output memory output)
        private
        pure
        returns (bool)
    {}
}
