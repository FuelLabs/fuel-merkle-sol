// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Proofs.sol";
import "./Branch.sol";
import "../Constants.sol";
import "../Utils.sol";

/// @notice A storage backed deep sparse Merkle subtree
/// @dev A DSMST is a SMT which can be minimally populated with branches
/// @dev This allows updating with only a minimal subset of leaves, assuming
/// @dev valid proofs are provided for those leaves
library SparseMerkleTree {
    /// @notice Get the pointer to a node in memory
    /// @param node: The node to get the pointer to
    /// @return ptr : The pointer to the node
    // solhint-disable-next-line func-visibility
    function getPtrToNode(Node memory node) internal pure returns (bytes32 ptr) {
        assembly {
            ptr := node
        }
    }

    /// @notice Get a node at a given pointer
    /// @param ptr: The pointer to the node
    /// @return node : The node
    // solhint-disable-next-line func-visibility
    function getNodeAtPtr(bytes32 ptr) internal pure returns (Node memory node) {
        assembly {
            node := ptr
        }
    }

    /// @notice Get the sidenodes for a given leaf key up to the root
    /// @param key: The key for which to find the sidenodes
    /// @param rootPtr: The memory pointer to the root of the tree
    /// @return The sidenodes up to the root, leaf hash, leaf data, and sibling data of the specified key
    // solhint-disable-next-line func-visibility
    function sideNodesForRoot(bytes32 key, bytes32 rootPtr)
        internal
        pure
        returns (
            bytes32[] memory,
            bytes32,
            Node memory,
            Node memory
        )
    {
        Node memory nullNode = Node(
            Constants.NULL,
            bytes1(0),
            Constants.NULL,
            Constants.NULL,
            Constants.NULL,
            ""
        );

        // Allocate a large enough array for the sidenodes (we'll shrink it later)
        bytes32[] memory sideNodes = new bytes32[](256);
        bytes32[] memory emptySideNodes;

        Node memory currentNode = getNodeAtPtr(rootPtr);

        // If the root is a placeholder, there are no sidenodes to return.
        // The currentNode is the root, and the sibling is null
        if (currentNode.digest == Constants.ZERO) {
            return (emptySideNodes, rootPtr, currentNode, nullNode);
        }

        // If the root is a leaf, there are also no sidenodes to return.
        // The data is the leaf data, and the sibling is null
        if (isLeaf(currentNode)) {
            return (emptySideNodes, rootPtr, currentNode, nullNode);
        }

        SideNodesFunctionVariables memory variables;
        variables.sideNodeCount = 0;

        // Descend the tree from the root according to the key, collecting side nodes
        for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
            (variables.leftNodePtr, variables.rightNodePtr) = parseNode(currentNode);
            // Bifurcate left or right depending on bit in key at this height
            if (getBitAtFromMSB(key, i) == 1) {
                (variables.nodePtr, variables.sideNodePtr) = (
                    variables.rightNodePtr,
                    variables.leftNodePtr
                );
            } else {
                (variables.nodePtr, variables.sideNodePtr) = (
                    variables.leftNodePtr,
                    variables.rightNodePtr
                );
            }

            sideNodes[variables.sideNodeCount] = variables.sideNodePtr;
            variables.sideNodeCount += 1;

            // If pointer iz zero, we have reached the end (Leaf not yet in tree)
            if (variables.nodePtr == Constants.NULL) {
                currentNode = nullNode;
                break;
            }

            currentNode = getNodeAtPtr(variables.nodePtr);

            // If the node is a leaf, we've reached the end. (Leaf already in tree)
            if (isLeaf(currentNode)) {
                break;
            }
        }

        return (
            reverseSideNodes(shrinkBytes32Array(sideNodes, variables.sideNodeCount)),
            variables.nodePtr,
            currentNode,
            getNodeAtPtr(variables.sideNodePtr)
        );
    }

    /// @notice Update a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be updated
    /// @param value: The new value
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafPtr: The hash of the leaf before the update
    /// @param oldLeafNode: The data of the leaf before the update
    /// @return The updated root of the tree
    // solhint-disable-next-line func-visibility
    function updateWithSideNodes(
        bytes32 key,
        bytes memory value,
        bytes32[] memory sideNodes,
        bytes32 oldLeafPtr,
        Node memory oldLeafNode
    ) internal pure returns (bytes32) {
        bytes32 currentPtr;
        Node memory currentNode;
        bytes32 actualPath;

        currentNode = hashLeaf(key, value);
        currentPtr = getPtrToNode(currentNode);

        // If the leaf node that sibling nodes lead to has a different actual path
        // than the leaf node being updated, we need to create an intermediate node
        // with this leaf node and the new leaf node as children.
        //
        // First, get the number of bits that the paths of the two leaf nodes share
        // in common as a prefix.

        uint256 commonPrefixCount;
        if (oldLeafPtr == Constants.NULL) {
            commonPrefixCount = Constants.MAX_HEIGHT;
        } else {
            (actualPath, ) = parseLeaf(oldLeafNode);
            commonPrefixCount = countCommonPrefix(key, actualPath);
        }

        if (commonPrefixCount != Constants.MAX_HEIGHT) {
            if (getBitAtFromMSB(key, commonPrefixCount) == 1) {
                currentNode = hashNode(
                    oldLeafPtr,
                    currentPtr,
                    getNodeAtPtr(oldLeafPtr).digest,
                    getNodeAtPtr(currentPtr).digest
                );
            } else {
                currentNode = hashNode(
                    currentPtr,
                    oldLeafPtr,
                    getNodeAtPtr(currentPtr).digest,
                    getNodeAtPtr(oldLeafPtr).digest
                );
            }
            currentPtr = getPtrToNode(currentNode);
        }

        for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
            bytes32 sideNodePtr;
            uint256 offsetOfSideNodes = Constants.MAX_HEIGHT - sideNodes.length;

            // If there are no sidenodes at this height, but the number of
            // bits that the paths of the two leaf nodes share in common is
            // greater than this height, then we need to build up the tree
            // to this height with placeholder values at siblings.

            // Removed 2nd condition here => || (sideNodes[i - offsetOfSideNodes] == ""/null)
            // as it can never be reached (?)
            if (i < offsetOfSideNodes) {
                if (
                    (commonPrefixCount != Constants.MAX_HEIGHT) &&
                    (commonPrefixCount > Constants.MAX_HEIGHT - 1 - i)
                ) {
                    sideNodePtr = Constants.NULL;
                } else {
                    continue;
                }
            } else {
                sideNodePtr = sideNodes[i - offsetOfSideNodes];
            }

            if (getBitAtFromMSB(key, Constants.MAX_HEIGHT - 1 - i) == 1) {
                currentNode = hashNode(
                    sideNodePtr,
                    currentPtr,
                    getNodeAtPtr(sideNodePtr).digest,
                    getNodeAtPtr(currentPtr).digest
                );
            } else {
                currentNode = hashNode(
                    currentPtr,
                    sideNodePtr,
                    getNodeAtPtr(currentPtr).digest,
                    getNodeAtPtr(sideNodePtr).digest
                );
            }

            currentPtr = getPtrToNode(currentNode);
        }

        return currentPtr;
    }

    /// @notice Delete a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be deleted
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafNode: The data of the leaf before the update
    /// @return The updated root of the tree
    /// @dev The leaf is updated to ZERO, and its sibling is percolated up the tree until it has a sibling
    // solhint-disable-next-line func-visibility
    function deleteWithSideNodes(
        bytes32 key,
        bytes32[] memory sideNodes,
        Node memory oldLeafNode,
        bytes32 rootPtr
    ) internal pure returns (bytes32) {
        // If value already zero, deletion changes nothing. Just return current root
        if (oldLeafNode.digest == Constants.ZERO) {
            return rootPtr;
        }

        // If key is already empty (different key found in its place), deletion changed nothing. Just return current root
        bytes32 actualPath;
        (actualPath, ) = parseLeaf(oldLeafNode);

        if (actualPath != key) {
            return rootPtr;
        }

        DeleteFunctionVariables memory variables;
        variables.nonPlaceholderReached = false;

        for (uint256 i = 0; i < sideNodes.length; i += 1) {
            if (sideNodes[i] == Constants.NULL) {
                continue;
            }
            variables.sideNodePtr = sideNodes[i];

            if (
                variables.currentNode.leftChildPtr == Constants.NULL &&
                variables.currentNode.rightChildPtr == Constants.NULL
            ) {
                variables.sideNode = getNodeAtPtr(variables.sideNodePtr);

                if (isLeaf(variables.sideNode)) {
                    // Sibling is a leaf:  needs to be percolated up the tree
                    variables.currentPtr = variables.sideNodePtr;
                    variables.currentNode = getNodeAtPtr(variables.sideNodePtr);
                    continue;
                } else {
                    // Sibling is a node: needs to be left in its place.
                    variables.nonPlaceholderReached = true;
                }
            }

            if (
                !variables.nonPlaceholderReached &&
                getNodeAtPtr(variables.sideNodePtr).digest == Constants.NULL
            ) {
                // We found another placeholder sibling node, keep going up the
                // tree until we find the first sibling that is not a placeholder.
                continue;
            } else if (!variables.nonPlaceholderReached) {
                // We found the first sibling node that is not a placeholder, it is
                // time to insert our leaf sibling node here.
                variables.nonPlaceholderReached = true;
            }

            if (getBitAtFromMSB(key, sideNodes.length - 1 - i) == 1) {
                variables.currentNode = hashNode(
                    variables.sideNodePtr,
                    variables.currentPtr,
                    getNodeAtPtr(variables.sideNodePtr).digest,
                    getNodeAtPtr(variables.currentPtr).digest
                );
            } else {
                variables.currentNode = hashNode(
                    variables.currentPtr,
                    variables.sideNodePtr,
                    getNodeAtPtr(variables.currentPtr).digest,
                    getNodeAtPtr(variables.sideNodePtr).digest
                );
            }

            variables.currentPtr = getPtrToNode(variables.currentNode);
        }

        return variables.currentPtr;
    }

    /// @notice Update the value of a leaf
    /// @param key: The key of the leaf to be updates
    /// @param value: The new value
    // solhint-disable-next-line func-visibility
    function update(
        bytes32 key,
        bytes memory value,
        bytes32 rootPtr
    ) internal pure returns (bytes32) {
        bytes32[] memory sideNodes;
        bytes32 oldLeafPtr;
        Node memory oldLeafNode;
        Node memory siblingNode;

        (sideNodes, oldLeafPtr, oldLeafNode, siblingNode) = sideNodesForRoot(key, rootPtr);

        bytes32 newRootPtr;
        if (isDefaultValue(value)) {
            newRootPtr = deleteWithSideNodes(key, sideNodes, oldLeafNode, rootPtr);
        } else {
            newRootPtr = updateWithSideNodes(key, value, sideNodes, oldLeafPtr, oldLeafNode);
        }

        return getNodeAtPtr(newRootPtr).digest;
    }

    /// @notice A struct to hold variables of the delete function in memory
    /// @dev Necessary to circumvent stack-too-deep errors caused by too many
    /// @dev variables on the stack.
    struct DeleteFunctionVariables {
        bytes32 currentPtr;
        Node currentNode;
        bytes32 sideNodePtr;
        Node sideNode;
        bool nonPlaceholderReached;
    }

    /// @notice A struct to hold variables of the sidenodes function in memory
    /// @dev Necessary to circumvent stack-too-deep errors caused by too many
    /// @dev variables on the stack.
    struct SideNodesFunctionVariables {
        bytes32 leftNodePtr;
        bytes32 rightNodePtr;
        bytes32 nodePtr;
        bytes32 sideNodePtr;
        uint256 sideNodeCount;
        bytes leafData;
    }

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
            Node memory rootNode = Node(
                root,
                Constants.LEAF_PREFIX,
                Constants.NULL,
                Constants.NULL,
                Constants.ZERO,
                ""
            );
            rootPtr = getPtrToNode(rootNode);
            variables.parent = rootNode;
        }
        // On subsequent branches, we need to retrieve root
        else {
            variables.parent = getNodeAtPtr(rootPtr);
        }

        // Step backwards through proof (from root down to leaf), getting pointers to the nodes/sideNodes
        // If node is not yet added, set digest to NULL (we'll set it when we hash back up the branch)
        for (uint256 i = proof.SideNodes.length; i > 0; i -= 1) {
            uint256 j = i - 1;

            // Parent has a child, so is a node
            variables.parent.prefix = Constants.NODE_PREFIX;

            // Descend into left or right subtree depending on key
            // If leaf is in the right subtree:
            if (getBitAtFromMSB(key, proof.SideNodes.length - i) == 1) {
                // Subtree is on the right, so sidenode is on the left.
                // Check to see if sidenode already exists. If not, create it. and associate with parent
                if (variables.parent.leftChildPtr == Constants.NULL) {
                    variables.sideNode = Node(
                        proof.SideNodes[j],
                        Constants.NODE_PREFIX,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.sideNodePtr = getPtrToNode(variables.sideNode);
                    variables.parent.leftChildPtr = variables.sideNodePtr;
                } else {
                    variables.sideNodePtr = variables.parent.leftChildPtr;
                }

                // Check to see if node already exists. If not, create it. and associate with parent
                // Its digest is initially null. We calculate and set it when we climb back up the tree
                if (variables.parent.rightChildPtr == Constants.NULL) {
                    variables.node = Node(
                        Constants.NULL,
                        Constants.LEAF_PREFIX,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.nodePtr = getPtrToNode(variables.node);
                    variables.parent.rightChildPtr = variables.nodePtr;
                } else {
                    variables.nodePtr = variables.parent.rightChildPtr;
                    variables.node = getNodeAtPtr(variables.nodePtr);
                }

                // Mirror image of preceding code block, for when leaf is in the left subtree
                // If subtree is on the left, sideNode is on the right
            } else {
                if (variables.parent.rightChildPtr == Constants.NULL) {
                    variables.sideNode = Node(
                        proof.SideNodes[j],
                        Constants.NODE_PREFIX,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.sideNodePtr = getPtrToNode(variables.sideNode);
                    variables.parent.rightChildPtr = variables.sideNodePtr;
                } else {
                    variables.sideNodePtr = variables.parent.rightChildPtr;
                }

                if (variables.parent.leftChildPtr == Constants.NULL) {
                    variables.node = Node(
                        Constants.NULL,
                        Constants.LEAF_PREFIX,
                        Constants.NULL,
                        Constants.NULL,
                        Constants.ZERO,
                        ""
                    );
                    variables.nodePtr = getPtrToNode(variables.node);
                    variables.parent.leftChildPtr = variables.nodePtr;
                } else {
                    variables.nodePtr = variables.parent.leftChildPtr;
                    variables.node = getNodeAtPtr(variables.nodePtr);
                }
            }

            // Keep pointers to sideNode and node
            sideNodePtrs[j] = variables.sideNodePtr;
            nodePtrs[j] = variables.nodePtr;

            variables.parent = variables.node;
        }

        // Set leaf digest
        Node memory leaf = getNodeAtPtr(nodePtrs[0]);
        leaf.digest = leafDigest(key, value);
        leaf.key = key;
        leaf.leafData = value;

        if (proof.SideNodes.length == 0) {
            return rootPtr;
        }

        // If sibling was a leaf, set its prefix to indicate that
        if (isLeaf(proof.Sibling)) {
            variables.node = getNodeAtPtr(sideNodePtrs[0]);
            variables.node.prefix = Constants.LEAF_PREFIX;
        }

        // Go back up the tree, setting the digests of nodes on the branch
        for (uint256 i = 1; i < nodePtrs.length; i += 1) {
            variables.node = getNodeAtPtr(nodePtrs[i]);
            variables.node.digest = nodeDigest(
                getNodeAtPtr(variables.node.leftChildPtr).digest,
                getNodeAtPtr(variables.node.rightChildPtr).digest
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
