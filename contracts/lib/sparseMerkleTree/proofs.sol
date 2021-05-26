//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./treeHasher.sol";
import "./utils.sol";
import "../constants.sol";

/// @notice A full (non-compact) sparse Merkle proof
struct SparseMerkleProof {
    bytes32[] SideNodes;
    bytes NonMembershipLeafData;
    bytes SiblingData;
}

/// @notice A sparse Merkle proof
/// @dev Minimal sidenodes are provided, with a bitmask indicating at which height they occur
struct SparseCompactMerkleProof {
    bytes32[] SideNodes;
    bytes NonMembershipLeafData;
    uint256[] BitMask;
    uint256 NumSideNodes;
    bytes SiblingData;
}

/// @notice An update (hash-value pair) to apply to a DSMST
struct UpdateFromProof {
    bytes32 updatedHash;
    bytes updatedValue;
}

/// @notice A struct to hold variables of the verify function in memory
/// @dev Necessary to circumvent stack-too-deep errors caused by too many
/// @dev variables on the stack.
struct VerifyFunctionVariables {
    bytes32 currentHash;
    bytes currentData;
    bytes32 actualPath;
    bytes32 valueHash;
}

/// @notice Verify a proof is valid
/// @param proof: A decompacted sparse Merkle proof
/// @param root: The root of the SMT containing the leaf to be proved
/// @param key: The key of the leave being proved
/// @param value: The value of the leaf
/// @return result : Whether the proof is valid or not
/// @return updates :  An array of updates to be applied to add the branch
// solhint-disable-next-line func-visibility
function verifyProof(
    SparseMerkleProof memory proof,
    bytes32 root,
    bytes32 key,
    bytes memory value
) pure returns (bool, UpdateFromProof[] memory) {
    UpdateFromProof[] memory updates = new UpdateFromProof[](256);

    VerifyFunctionVariables memory variables;

    /// @dev No bytes comparison in solidity, compare hashes instead
    if (isDefaultValue(value)) {
        // Non-membership proof
        if (proof.NonMembershipLeafData.length == 0) {
            variables.currentHash = Constants.ZERO;
        } else {
            // leaf is an unrelated leaf
            (variables.actualPath, variables.valueHash) = parseLeaf(proof.NonMembershipLeafData);
            if (variables.actualPath == key) {
                // Leaf does exist: non-membership proof failed
                return (false, updates);
            }
            (variables.currentHash, variables.currentData) = hashLeaf(
                variables.actualPath,
                abi.encodePacked(variables.valueHash)
            );
            updates[0] = UpdateFromProof(variables.currentHash, variables.currentData);
        }
    } else {
        // Membership proof
        variables.valueHash = hash(value);
        (variables.currentHash, variables.currentData) = hashLeaf(key, value);
        updates[0] = UpdateFromProof(variables.currentHash, variables.currentData);
    }

    // Recompute root
    for (uint256 i = 0; i < proof.SideNodes.length; i += 1) {
        bytes32 node = proof.SideNodes[i];

        if (getBitAtFromMSB(key, proof.SideNodes.length - 1 - i) == 1) {
            (variables.currentHash, variables.currentData) = hashNode(node, variables.currentHash);
        } else {
            (variables.currentHash, variables.currentData) = hashNode(variables.currentHash, node);
        }

        updates[i + 1] = UpdateFromProof(variables.currentHash, variables.currentData);
    }

    return (variables.currentHash == root, shrinkUpdatesArray(updates, proof.SideNodes.length + 1));
}

/// @notice Turn a sparse Merkle proof into a compact sparse Merkle proof
/// @param proof: The sparse Merkle proof
// solhint-disable-next-line func-visibility
function compactProof(SparseMerkleProof memory proof)
    pure
    returns (SparseCompactMerkleProof memory)
{
    uint256[] memory bitMask = new uint256[](proof.SideNodes.length);
    // Create a large-enough dynamic array for the sidenodes
    bytes32[] memory compactedSideNodes = new bytes32[](256);
    bytes32 node;
    uint256 sideNodesCount = 0;

    /// Compact proof into array of non-zero sidenodes and a bitmask
    for (uint256 i = 0; i < proof.SideNodes.length; i += 1) {
        node = proof.SideNodes[i];
        if (node == Constants.ZERO) {
            bitMask[i] = 0;
        } else {
            compactedSideNodes[sideNodesCount] = node;
            bitMask[i] = 1;
        }
    }

    /// Shrink the array of sidenodes to its final size
    bytes32[] memory finalCompactedSideNodes =
        shrinkBytes32Array(compactedSideNodes, sideNodesCount);

    return
        SparseCompactMerkleProof(
            finalCompactedSideNodes,
            proof.NonMembershipLeafData,
            bitMask,
            proof.SideNodes.length,
            proof.SiblingData
        );
}

/// @notice Turns a Compact sparse Merkle proof into a full sparse Merkle proof
/// @param proof: The Compact proof to be decompacted
// solhint-disable-next-line func-visibility
function decompactProof(SparseCompactMerkleProof memory proof)
    pure
    returns (SparseMerkleProof memory)
{
    bytes32[] memory decompactedSideNodes = new bytes32[](proof.NumSideNodes);
    uint256 position = 0;

    for (uint256 i = 0; i < proof.NumSideNodes; i += 1) {
        if (proof.BitMask[i] == 0) {
            decompactedSideNodes[i] = Constants.ZERO;
        } else {
            decompactedSideNodes[i] = proof.SideNodes[position];
            position += 1;
        }
    }

    return SparseMerkleProof(decompactedSideNodes, proof.NonMembershipLeafData, proof.SiblingData);
}
