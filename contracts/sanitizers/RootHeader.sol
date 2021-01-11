// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../types/TransactionProof.sol";
import "../types/RootHeader.sol";

/// @title Root header sanitizer
library RootHeaderSanitizer {
    /////////////
    // Methods //
    /////////////

    /// @notice Sanitize a root header.
    /// @param proof The transaction proof.
    function sanitizeRootHeader(TransactionProof calldata proof) internal pure {
        BlockHeader calldata blockHeader = proof.blockHeader;
        RootHeader calldata rootHeader = proof.rootHeader;

        // Check bounds on transaction root index
        require(
            proof.rootIndex < blockHeader.roots.length,
            "root-index-underflow"
        );

        // Hash of root header must match root header hash from proof
        require(
            keccak256(abi.encode(rootHeader)) ==
                blockHeader.roots[proof.rootIndex],
            "root-block"
        );
    }
}
