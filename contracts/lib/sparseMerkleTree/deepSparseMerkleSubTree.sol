//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./sparseMerkleTree.sol";
import "./proofs.sol";

/// @notice A storage backed deep sparse Merkle subtree
/// @dev A DSMST is a SMT which can be minimally populated with branches
/// @dev This allows updating with only a minimal subset of leaves, assuming
/// @dev valid proofs are provided for those leaves
contract DeepSparseMerkleSubTree is SparseMerkleTree {
    /// @notice Constructor. Sets the root of the DSMST
    /// @param _root: The root of the sparse Merkle tree
    constructor(bytes32 _root) {
        setRoot(_root);
    }

    /// @notice Verify a proof is valid
    /// @param proof: A decompacted sparse Merkle proof
    /// @param key: The key of the leave being proved
    /// @param value: The value of the leaf
    /// @return result : Whether the proof is valid or not
    function verify(
        SparseMerkleProof memory proof,
        bytes32 key,
        bytes memory value
    ) public view returns (bool result) {
        (result, ) = verifyProof(proof, root, key, value);
    }

    /// @notice Adds a branch to the DSMST
    /// @param proof: The proof of the leaf to be added
    /// @param key: The key of the leaf
    /// @param value: The value of the leaf
    /// @return Whether the addition was a success
    function addBranch(
        SparseMerkleProof memory proof,
        bytes32 key,
        bytes memory value
    ) public returns (bool) {
        UpdateFromProof[] memory updates;
        bool result;

        // Verify the proof and get the updates to apply
        (result, updates) = verifyProof(proof, root, key, value);

        if (!result) {
            return false;
        }

        // Apply the updates
        for (uint256 i = 0; i < updates.length; i += 1) {
            set(updates[i].updatedHash, updates[i].updatedValue);
        }

        if (proof.SiblingData.length != 0) {
            if (proof.SideNodes.length > 0) {
                set(proof.SideNodes[0], proof.SiblingData);
            }
        }

        return true;
    }

    /// @notice Verify a compact proof
    /// @param proof The Compact proof
    /// @param key: The key of the leaf to be proved
    /// @param value: The value of the leaf
    /// @return Whether the proof is valid or not
    function verifyCompact(
        SparseCompactMerkleProof memory proof,
        bytes32 key,
        bytes memory value
    ) public view returns (bool) {
        // Decompact the proof
        SparseMerkleProof memory decompactedProof = decompactProof(proof);

        // Verify the decompacted proof
        return verify(decompactedProof, key, value);
    }

    /// @notice Add a branch using a compact proof
    /// @param proof: The compact Merkle proof
    /// @param key: The key of the leaf to be proved
    /// @param value: The value of the leaf
    /// @return Whether the addition was a success
    function addBranchCompact(
        SparseCompactMerkleProof memory proof,
        bytes32 key,
        bytes memory value
    ) public returns (bool) {
        SparseMerkleProof memory decompactedProof = decompactProof(proof);
        return addBranch(decompactedProof, key, value);
    }
}
