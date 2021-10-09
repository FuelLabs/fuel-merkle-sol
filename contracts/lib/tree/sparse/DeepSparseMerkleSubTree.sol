// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SparseMerkleTree.sol";
import "./Proofs.sol";
import "./Branch.sol";
import "../Constants.sol";
import "../Utils.sol";

/// @notice A storage backed deep sparse Merkle subtree
/// @dev A DSMST is a SMT which can be minimally populated with branches
/// @dev This allows updating with only a minimal subset of leaves, assuming
/// @dev valid proofs are provided for those leaves
contract DeepSparseMerkleSubTree is SparseMerkleTree {
    /// @notice Verify a proof is valid
    /// @param proof: A decompacted sparse Merkle proof
    /// @param key: The key of the leave being proved
    /// @param value: The value of the leaf
    /// @return result : Whether the proof is valid or not
    function verify(
        SparseMerkleProof memory proof,
        bytes32 key,
        bytes memory value,
        bytes32 root
    ) public pure returns (bool result) {
        result = verifyProof(proof, root, key, value);
    }

    /// @notice Adds a branch to the DSMST
    /// @param proof: The proof of the leaf to be added
    /// @param key: The key of the leaf
    /// @param value: The value of the leaf
    /// @param root: The root of the branch
    function addBranch(
        SparseMerkleProof memory proof,
        bytes32 key,
        bytes memory value,
        bytes32 root,
        bytes32 rootPtr
    ) public pure returns (bytes32) {
        AddBranchVariables memory variables;

        bytes32[] memory sideNodePtrs = new bytes32[](proof.SideNodes.length);
        bytes32[] memory nodePtrs = new bytes32[](proof.SideNodes.length);

        // Set root
        // When adding the first branch, rootPtr will not be set yet, set it here.
        if (rootPtr == Constants.NULL) {
            // Set the new root
            Node memory rootNode =
                Node(root, leafPrefix, Constants.NULL, Constants.NULL, Constants.ZERO, "");
            rootPtr = set(rootNode);
            variables.parent = rootNode;
        }
        // On subsequent branches, we need to retrieve root
        else {
            variables.parent = get(rootPtr);
        }

        // Step backwards through proof (from root down to leaf), getting pointers to the nodes/sideNodes
        // If node is not yet added, set digest to NULL (we'll set it when we hash back up the branch)
        for (uint256 i = proof.SideNodes.length; i > 0; i -= 1) {
            uint256 j = i - 1;

            // Parent has a child, so is a node
            variables.parent.prefix = nodePrefix;

            // Descend into left or right subtree depending on key
            // If leaf is in the right subtree:
            if (getBitAtFromMSB(key, proof.SideNodes.length - i) == 1) {
                // Subtree is on the right, so sidenode is on the left.
                // Check to see if sidenode already exists. If not, create it. and associate with parent
                if (variables.parent.leftChildPtr == Constants.NULL) {
                    variables.sideNode = Node(
                        proof.SideNodes[j],
                        nodePrefix,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.sideNodePtr = set(variables.sideNode);
                    variables.parent.leftChildPtr = variables.sideNodePtr;
                } else {
                    variables.sideNodePtr = variables.parent.leftChildPtr;
                }

                // Check to see if node already exists. If not, create it. and associate with parent
                // Its digest is initially null. We calculate and set it when we climb back up the tree
                if (variables.parent.rightChildPtr == Constants.NULL) {
                    variables.node = Node(
                        Constants.NULL,
                        leafPrefix,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.nodePtr = set(variables.node);
                    variables.parent.rightChildPtr = variables.nodePtr;
                } else {
                    variables.nodePtr = variables.parent.rightChildPtr;
                    variables.node = get(variables.nodePtr);
                }

                // Mirror image of preceding code block, for when leaf is in the left subtree
                // If subtree is on the left, sideNode is on the right
            } else {
                if (variables.parent.rightChildPtr == Constants.NULL) {
                    variables.sideNode = Node(
                        proof.SideNodes[j],
                        nodePrefix,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.sideNodePtr = set(variables.sideNode);
                    variables.parent.rightChildPtr = variables.sideNodePtr;
                } else {
                    variables.sideNodePtr = variables.parent.rightChildPtr;
                }

                if (variables.parent.leftChildPtr == Constants.NULL) {
                    variables.node = Node(
                        Constants.NULL,
                        leafPrefix,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.nodePtr = set(variables.node);
                    variables.parent.leftChildPtr = variables.nodePtr;
                } else {
                    variables.nodePtr = variables.parent.leftChildPtr;
                    variables.node = get(variables.nodePtr);
                }
            }

            // Keep pointers to sideNode and node
            sideNodePtrs[j] = variables.sideNodePtr;
            nodePtrs[j] = variables.nodePtr;

            variables.parent = variables.node;
        }

        // Set leaf digest
        Node memory leaf = get(nodePtrs[0]);
        leaf.digest = leafDigest(key, value);
        leaf.key = key;
        leaf.leafData = value;

        if (proof.SideNodes.length == 0) {
            return rootPtr;
        }

        // If sibling was a leaf, set its prefix to indicate that
        if (isLeaf(proof.Sibling)) {
            variables.node = get(sideNodePtrs[0]);
            variables.node.prefix = leafPrefix;
        }

        // Go back up the tree, setting the digests of nodes on the branch
        for (uint256 i = 1; i < nodePtrs.length; i += 1) {
            variables.node = get(nodePtrs[i]);
            variables.node.digest = nodeDigest(
                get(variables.node.leftChildPtr).digest,
                get(variables.node.rightChildPtr).digest
            );
        }

        return rootPtr;
    }

    /// @notice Verify a compact proof
    /// @param proof The Compact proof
    /// @param key: The key of the leaf to be proved
    /// @param value: The value of the leaf
    /// @return Whether the proof is valid or not
    function verifyCompact(
        SparseCompactMerkleProof memory proof,
        bytes32 key,
        bytes memory value,
        bytes32 root
    ) public pure returns (bool) {
        // Decompact the proof
        SparseMerkleProof memory decompactedProof = decompactProof(proof);

        // Verify the decompacted proof
        return verify(decompactedProof, key, value, root);
    }

    /// @notice Add a branch using a compact proof
    /// @param proof: The compact Merkle proof
    /// @param key: The key of the leaf to be proved
    /// @param value: The value of the leaf
    /// @return Whether the addition was a success
    function addBranchCompact(
        SparseCompactMerkleProof memory proof,
        bytes32 key,
        bytes memory value,
        bytes32 root,
        bytes32 rootPtr
    ) public pure returns (bytes32) {
        SparseMerkleProof memory decompactedProof = decompactProof(proof);
        return addBranch(decompactedProof, key, value, root, rootPtr);
    }

    function addBranchesAndUpdate(
        MerkleBranch[] memory branches,
        bytes32 root,
        bytes32 key,
        bytes memory value
    ) public pure returns (bytes32 newRoot) {
        bytes32 rootPtr = Constants.ZERO;
        for (uint256 i = 0; i < branches.length; i++) {
            rootPtr = addBranchCompact(
                branches[i].proof,
                branches[i].key,
                branches[i].value,
                root,
                rootPtr
            );
        }

        newRoot = update(key, value, rootPtr);
    }

    function addBranchesAndDelete(
        MerkleBranch[] memory branches,
        bytes32 root,
        bytes32 key
    ) public pure returns (bytes32 newRoot) {
        newRoot = addBranchesAndUpdate(branches, root, key, abi.encodePacked(Constants.ZERO));
    }

    struct AddBranchVariables {
        bytes32 nodePtr;
        bytes32 sideNodePtr;
        Node node;
        Node parent;
        Node sideNode;
    }
}
