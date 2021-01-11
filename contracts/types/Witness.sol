// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

enum WitnessType {
    // Regular signature
    Signature,
    // Contract call
    Caller,
    // Implicitly the block producer
    Producer
}

/// @notice Transaction witness
struct Witness {
    // Witness type
    WitnessType t;
    ///////////////
    // Signature //
    ///////////////
    bytes32 r;
    bytes32 s;
    uint8 v;
    ////////////
    // Caller //
    ////////////
    address owner;
    uint32 blockNumber;
    //////////////
    // Producer //
    //////////////
    bytes32 hash;
}

/// @notice Witness helper functions
library WitnessHelper {
    /////////////
    // Methods //
    /////////////

    /// @notice Try to parse witness bytes.
    function parseWitness(bytes calldata s)
        internal
        pure
        returns (
            Witness memory,
            uint256,
            bool
        )
    {
        // TODO
    }

    /// @notice Get size of a witness object.
    /// @return Size of witness in bytes.
    function witnessSize(Witness memory witness) internal pure returns (uint8) {
        // TODO double check these sizes
        if (witness.t == WitnessType.Signature) {
            return 66;
        } else if (witness.t == WitnessType.Caller) {
            return 53;
        } else if (witness.t == WitnessType.Producer) {
            return 33;
        }
        // avoid infinite loops
        // TODO can we remove this?
        return 66;
    }
}
