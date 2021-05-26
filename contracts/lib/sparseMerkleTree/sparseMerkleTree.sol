//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./utils.sol";
import "./treeHasher.sol";
import "./proofs.sol";
import "../constants.sol";

/// @notice A storage-backed Sparse Merkle Tree
contract SparseMerkleTree {
    /// @dev The mapping of nodes to their data
    mapping(bytes32 => bytes) public nodes;

    /// @dev The root of the tree
    bytes32 public root;

    /// @notice Constructor: Sets root to default value
    constructor() {
        root = Constants.ZERO;
        set(root, abi.encodePacked(Constants.ZERO));
    }

    /// @notice Set the value of a node
    /// @param key: The key (in the mapping) of the leaf to be set
    /// @param data: The data to set
    function set(bytes32 key, bytes memory data) internal {
        nodes[key] = data;
    }

    /// @notice Get the data of a given node, by key in the mapping
    /// @param key: The key in the mapping where the data is stored
    /// @return The data found at that key
    function get(bytes32 key) internal view returns (bytes memory) {
        return nodes[key];
    }

    /// @notice Set the root of the tree
    /// @param _root: The value to set
    function setRoot(bytes32 _root) internal {
        root = _root;
    }

    /// @notice Get the sidenodes for a given leaf key up to the root
    /// @param key: The key for which to find the sidenodes
    /// @param _root: The current root of the tree
    /// @return The sidenodes up to the root, leaf hash, leaf data, and sibling data of the specified key
    function sideNodesForRoot(bytes32 key, bytes32 _root)
        internal
        view
        returns (
            bytes32[] memory,
            bytes32,
            bytes memory,
            bytes memory
        )
    {
        // Allocate a large enough array for the sidenodes (we'll shrink it later)
        bytes32[] memory sideNodes = new bytes32[](256);
        bytes32[] memory emptySideNodes;

        // If the root is a placeholder, there are no sidenodes to return.
        // The data is nil, and the sibling is nil
        if (_root == Constants.ZERO) {
            return (emptySideNodes, Constants.ZERO, "", "");
        }

        bytes memory currentData = get(_root);

        // If the root is a leaf, there are also no sidenodes to return.
        // The data is the leaf data, and the sibling is nil
        if (isLeaf(currentData)) {
            return (emptySideNodes, _root, currentData, "");
        }

        bytes32 leftNode;
        bytes32 rightNode;
        NodePair memory nodePair;

        uint256 sideNodeCount = 0;

        // Descend the tree from the root according to the key, collecting side nodes
        for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
            (leftNode, rightNode) = parseNode(currentData);
            // Bifurcate left or right depending on bit in key at this height
            if (getBitAtFromMSB(key, i) == 1) {
                // nodePair is {nodeHash, sideNode}
                nodePair = NodePair(rightNode, leftNode);
            } else {
                nodePair = NodePair(leftNode, rightNode);
            }

            sideNodes[sideNodeCount] = nodePair.sideNode;
            sideNodeCount += 1;

            // If the node is a placeholder, we've reached the end.
            if (nodePair.nodeHash == Constants.ZERO) {
                currentData = "";
                break;
            }

            currentData = get(nodePair.nodeHash);

            // If the node is a leaf, we've reached the end.
            if (isLeaf(currentData)) {
                break;
            }
        }

        return (
            reverseSideNodes(shrinkBytes32Array(sideNodes, sideNodeCount)),
            nodePair.nodeHash,
            currentData,
            get(nodePair.sideNode)
        );
    }

    /// @notice Update a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be updated
    /// @param value: The new value
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafHash: The hash of the leaf before the update
    /// @param oldLeafData: The data of the leaf before the update
    /// @return The updated root of the tree
    function updateWithSideNodes(
        bytes32 key,
        bytes memory value,
        bytes32[] memory sideNodes,
        bytes32 oldLeafHash,
        bytes memory oldLeafData
    ) internal returns (bytes32) {
        bytes32 currentHash;
        bytes memory currentData;
        bytes32 actualPath;

        set(hash(value), value);

        (currentHash, currentData) = hashLeaf(key, value);
        set(currentHash, currentData);

        // If the leaf node that sibling nodes lead to has a different actual path
        // than the leaf node being updated, we need to create an intermediate node
        // with this leaf node and the new leaf node as children.
        //
        // First, get the number of bits that the paths of the two leaf nodes share
        // in common as a prefix.

        uint256 commonPrefixCount;
        if (oldLeafHash == Constants.ZERO) {
            commonPrefixCount = Constants.MAX_HEIGHT;
        } else {
            (actualPath, ) = parseLeaf(oldLeafData);
            commonPrefixCount = countCommonPrefix(key, actualPath);
        }

        if (commonPrefixCount != Constants.MAX_HEIGHT) {
            if (getBitAtFromMSB(key, commonPrefixCount) == 1) {
                (currentHash, currentData) = hashNode(oldLeafHash, currentHash);
            } else {
                (currentHash, currentData) = hashNode(currentHash, oldLeafHash);
            }
            set(currentHash, currentData);
        }

        for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
            bytes32 sideNode;
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
                    sideNode = Constants.ZERO;
                } else {
                    continue;
                }
            } else {
                sideNode = sideNodes[i - offsetOfSideNodes];
            }

            if (getBitAtFromMSB(key, Constants.MAX_HEIGHT - 1 - i) == 1) {
                (currentHash, currentData) = hashNode(sideNode, currentHash);
            } else {
                (currentHash, currentData) = hashNode(currentHash, sideNode);
            }

            set(currentHash, currentData);
        }

        return currentHash;
    }

    /// @notice Delete a key, given the sidenodes to the root
    /// @param key: The key of the leaf to be deleted
    /// @param sideNodes: The sidenodes between the leaf and the root
    /// @param oldLeafHash: The hash of the leaf before the update
    /// @param oldLeafData: The data of the leaf before the update
    /// @return The updated root of the tree
    /// @dev The leaf is updated to ZERO, and its sibling is percolated up the tree until it has a sibling
    function deleteWithSideNodes(
        bytes32 key,
        bytes32[] memory sideNodes,
        bytes32 oldLeafHash,
        bytes memory oldLeafData
    ) internal returns (bytes32) {
        // If value already zero, deletion changes nothing. Just return current root
        if (oldLeafHash == Constants.ZERO) {
            return root;
        }

        // If key is already empty (different key found in its place), deletion changed nothing. Just return current root
        bytes32 actualPath;
        (actualPath, ) = parseLeaf(oldLeafData);

        if (actualPath != key) {
            return root;
        }

        bytes32 currentHash;
        bytes memory currentData;
        bytes32 sideNode;
        bytes memory sideNodeValue;
        bool nonPlaceholderReached = false;

        for (uint256 i = 0; i < sideNodes.length; i += 1) {
            if (sideNodes[i] == "") {
                continue;
            }
            sideNode = sideNodes[i];

            if (currentData.length == 0) {
                sideNodeValue = get(sideNode);

                if (isLeaf(sideNodeValue)) {
                    // This is the leaf sibling that needs to be percolated up the tree.
                    currentHash = sideNode;
                    continue;
                } else {
                    // This is the node sibling that needs to be left in its place.
                    nonPlaceholderReached = true;
                }
            }

            if (!nonPlaceholderReached && sideNode == Constants.ZERO) {
                // We found another placeholder sibling node, keep going up the
                // tree until we find the first sibling that is not a placeholder.
                continue;
            } else if (!nonPlaceholderReached) {
                // We found the first sibling node that is not a placeholder, it is
                // time to insert our leaf sibling node here.
                nonPlaceholderReached = true;
            }

            if (getBitAtFromMSB(key, sideNodes.length - 1 - i) == 1) {
                (currentHash, currentData) = hashNode(sideNode, currentHash);
            } else {
                (currentHash, currentData) = hashNode(currentHash, sideNode);
            }

            set(currentHash, currentData);
        }
        return currentHash;
    }

    /// @notice Update the value of a leaf
    /// @param key: The key of the leaf to be updates
    /// @param value: The new value
    function update(bytes32 key, bytes memory value) public {
        bytes32[] memory sideNodes;
        bytes32 oldLeafHash;
        bytes memory oldLeafData;
        bytes memory siblingData;

        (sideNodes, oldLeafHash, oldLeafData, siblingData) = sideNodesForRoot(key, root);

        bytes32 newRoot;
        if (isDefaultValue(value)) {
            newRoot = deleteWithSideNodes(key, sideNodes, oldLeafHash, oldLeafData);
        } else {
            newRoot = updateWithSideNodes(key, value, sideNodes, oldLeafHash, oldLeafData);
        }

        setRoot(newRoot);
    }

    /// @notice Delete a leaf from the tree
    /// @param key: The key of the leaf to be deleted
    /// @dev The leaf is updated to ZERO, and its sibling is percolated up the tree until it has a sibling
    function del(bytes32 key) public {
        update(key, abi.encodePacked(Constants.ZERO));
    }
}
