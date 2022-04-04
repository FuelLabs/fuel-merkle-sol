// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./TreeHasher.sol";
import "../Utils.sol";
import "../Constants.sol";
import "./Node.sol";

/// @notice A full (non-compact) sparse Merkle proof
struct SparseMerkleProof {
    bytes32[] SideNodes;
    Node NonMembershipLeaf;
    Node Sibling;
}

/// @notice A sparse Merkle proof
/// @dev Minimal sidenodes are provided, with a bitmask indicating at which height they occur
struct SparseCompactMerkleProof {
    bytes32[] SideNodes;
    Node NonMembershipLeaf;
    uint256[] BitMask;
    uint256 NumSideNodes;
    Node Sibling;
}

/// @notice Verify a proof is valid
/// @param proof: A decompacted sparse Merkle proof
/// @param root: The root of the SMT containing the leaf to be proved
/// @param key: The key of the leave being proved
/// @param value: The value of the leaf
/// @return result : Whether the proof is valid or not
// solhint-disable-next-line func-visibility
function verifyProof(
    SparseMerkleProof memory proof,
    bytes32 root,
    bytes32 key,
    bytes memory value
) pure returns (bool) {
    bytes32 currentHash;
    bytes32 actualPath;
    bytes memory data;

    /// @dev No bytes comparison in solidity, compare hashes instead
    if (isDefaultValue(value)) {
        // Non-membership proof
        if (proof.NonMembershipLeaf.digest == Constants.ZERO) {
            currentHash = Constants.ZERO;
        } else {
            // leaf is an unrelated leaf
            (actualPath, data) = parseLeaf(proof.NonMembershipLeaf);
            if (actualPath == key) {
                // Leaf does exist: non-membership proof failed
                return false;
            }
            currentHash = leafDigest(actualPath, data);
        }
    } else {
        // Membership proof
        currentHash = leafDigest(key, value);
    }

    // Recompute root.
    for (uint256 i = 0; i < proof.SideNodes.length; i += 1) {
        if (getBitAtFromMSB(key, proof.SideNodes.length - 1 - i) == 1) {
            currentHash = nodeDigest(proof.SideNodes[i], currentHash);
        } else {
            currentHash = nodeDigest(currentHash, proof.SideNodes[i]);
        }
    }
    return (currentHash == root);
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
    bytes32[] memory finalCompactedSideNodes = shrinkBytes32Array(
        compactedSideNodes,
        sideNodesCount
    );

    return
        SparseCompactMerkleProof(
            finalCompactedSideNodes,
            proof.NonMembershipLeaf,
            bitMask,
            proof.SideNodes.length,
            proof.Sibling
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

    return SparseMerkleProof(decompactedSideNodes, proof.NonMembershipLeaf, proof.Sibling);
}
