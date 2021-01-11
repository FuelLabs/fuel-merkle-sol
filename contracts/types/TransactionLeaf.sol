// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./Input.sol";
import "./Metadata.sol";
import "./Output.sol";
import "./Witness.sol";

/// @notice Leaf of transaction Merkle tree.
struct TransactionLeaf {
    // Length of leaf in bytes
    uint16 length;
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
        // TODO
    }
}
