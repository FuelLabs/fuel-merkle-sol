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
        Witness memory witness;
        uint256 bytesUsed;

        // Type
        uint8 typeRaw = uint8(abi.decode(s[0:1], (bytes1)));
        if (typeRaw > uint8(WitnessType.Producer))
            return (witness, bytesUsed, false);
        witness.t = WitnessType(typeRaw);

        bytesUsed = _witnessSize(witness);
        if (s.length < bytesUsed) {
            return (witness, bytesUsed, false);
        }

        if (witness.t == WitnessType.Signature) {
            // Signature
            witness.r = bytes32(abi.decode(s[1:33], (bytes32)));
            witness.r = bytes32(abi.decode(s[33:65], (bytes32)));
            witness.v = uint8(abi.decode(s[65:66], (bytes1)));
        } else if (witness.t == WitnessType.Caller) {
            // Caller
            witness.owner = address(abi.decode(s[1:21], (bytes20)));
            witness.blockNumber = uint32(abi.decode(s[21:25], (bytes4)));
        } else if (witness.t == WitnessType.Producer) {
            // Producer
            witness.hash = bytes32(abi.decode(s[1:33], (bytes32)));
        } else {
            revert();
        }

        return (witness, bytesUsed, true);
    }

    /// @notice Get size of a witness object.
    /// @return Size of witness in bytes.
    function _witnessSize(Witness memory witness) private pure returns (uint8) {
        // TODO double check these sizes
        if (witness.t == WitnessType.Signature) {
            return 66;
        } else if (witness.t == WitnessType.Caller) {
            return 25;
        } else if (witness.t == WitnessType.Producer) {
            return 33;
        }

        revert();
    }
}
