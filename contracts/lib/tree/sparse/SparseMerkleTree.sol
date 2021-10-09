// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../Utils.sol";
import "./TreeHasher.sol";
import "./Proofs.sol";
import "../Constants.sol";
import "./Node.sol";

/// @notice A memory-backed Sparse Merkle Tree
contract SparseMerkleTree {
    /// @notice Set the value of a node
    /// @param node: The node to be set
    /// @return ptr : The pointer to the node that was set
    /// @dev The parameter type is 'Node memory': the node is already in memory, so the param is actually a pointer to this node
    /// @dev We need to be able to "find" this pointer later, so we save it in memory and return a new pointer TO this pointer.
    function set(Node memory node) internal pure returns (bytes32 ptr) {
        assembly {
            // Store pointer to the node at the next available slot
            ptr := mload(0x40)
            mstore(ptr, node)

            // Increment free memory pointer by 32 bytes
            mstore(0x40, add(ptr, 0x20))
        }
    }

    /// @notice Get a given node, from its pointer
    /// @param ptr: The pointer to where the data is stored in memory
    /// @return node : The node found at that key
    function get(bytes32 ptr) internal pure returns (Node memory node) {
        assembly {
            // Reads a "Node" struct from memory, starting from the pointer given.
            // The size of the object to be read (number of contiguous bytes in memory)
            // and the properties which that data encodes are implicit in the
            // assignment to a variable of type 'Node'.
            node := mload(ptr)
        }
    }

    /// @notice Get the sidenodes for a given leaf key up to the root
    /// @param key: The key for which to find the sidenodes
    /// @param rootPtr: The memory pointer to the root of the tree
    /// @return The sidenodes up to the root, leaf hash, leaf data, and sibling data of the specified key
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
        Node memory nullNode =
            Node(Constants.NULL, bytes1(0), Constants.NULL, Constants.NULL, Constants.NULL, "");

        // Allocate a large enough array for the sidenodes (we'll shrink it later)
        bytes32[] memory sideNodes = new bytes32[](256);
        bytes32[] memory emptySideNodes;

        Node memory currentNode = get(rootPtr);

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

            currentNode = get(variables.nodePtr);

            // If the node is a leaf, we've reached the end. (Leaf already in tree)
            if (isLeaf(currentNode)) {
                break;
            }
        }

        return (
            reverseSideNodes(shrinkBytes32Array(sideNodes, variables.sideNodeCount)),
            variables.nodePtr,
            currentNode,
            get(variables.sideNodePtr)
        );
    }

    /// @notice Update a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be updated
    /// @param value: The new value
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafPtr: The hash of the leaf before the update
    /// @param oldLeafNode: The data of the leaf before the update
    /// @return The updated root of the tree
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
        currentPtr = set(currentNode);

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
                    get(oldLeafPtr).digest,
                    get(currentPtr).digest
                );
            } else {
                currentNode = hashNode(
                    currentPtr,
                    oldLeafPtr,
                    get(currentPtr).digest,
                    get(oldLeafPtr).digest
                );
            }
            currentPtr = set(currentNode);
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
                    get(sideNodePtr).digest,
                    get(currentPtr).digest
                );
            } else {
                currentNode = hashNode(
                    currentPtr,
                    sideNodePtr,
                    get(currentPtr).digest,
                    get(sideNodePtr).digest
                );
            }

            currentPtr = set(currentNode);
        }

        return currentPtr;
    }

    /// @notice Delete a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be deleted
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafNode: The data of the leaf before the update
    /// @return The updated root of the tree
    /// @dev The leaf is updated to ZERO, and its sibling is percolated up the tree until it has a sibling
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
                variables.sideNode = get(variables.sideNodePtr);

                if (isLeaf(variables.sideNode)) {
                    // Sibling is a leaf:  needs to be percolated up the tree
                    variables.currentPtr = variables.sideNodePtr;
                    variables.currentNode = get(variables.sideNodePtr);
                    continue;
                } else {
                    // Sibling is a node: needs to be left in its place.
                    variables.nonPlaceholderReached = true;
                }
            }

            if (
                !variables.nonPlaceholderReached &&
                get(variables.sideNodePtr).digest == Constants.NULL
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
                    get(variables.sideNodePtr).digest,
                    get(variables.currentPtr).digest
                );
            } else {
                variables.currentNode = hashNode(
                    variables.currentPtr,
                    variables.sideNodePtr,
                    get(variables.currentPtr).digest,
                    get(variables.sideNodePtr).digest
                );
            }

            variables.currentPtr = set(variables.currentNode);
        }

        return variables.currentPtr;
    }

    /// @notice Update the value of a leaf
    /// @param key: The key of the leaf to be updates
    /// @param value: The new value
    function update(
        bytes32 key,
        bytes memory value,
        bytes32 rootPtr
    ) public pure returns (bytes32) {
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

        return get(newRootPtr).digest;
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
}
