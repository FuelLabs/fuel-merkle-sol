// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../Constants.sol";
import "./Node.sol";

/// @notice Calculate the starting bit of the path to a leaf
/// @param numLeaves : The total number of leaves in the tree
/// @return startingBit : The starting bit of the path
// solhint-disable-next-line func-visibility
function getStartingBit(uint256 numLeaves) pure returns (uint256 startingBit) {
    // Determine height of the left subtree. This is the maximum path length, so all paths start at this offset from the right-most bit
    startingBit = 0;
    while ((1 << startingBit) < numLeaves) {
        startingBit += 1;
    }
    return Constants.MAX_HEIGHT - startingBit;
}

/// @notice Calculate the length of the path to a leaf
/// @param key: The key of the leaf
/// @param numLeaves: The total number of leaves in the tree
/// @return pathLength : The length of the path to the leaf
// solhint-disable-next-line func-visibility
function pathLengthFromKey(uint256 key, uint256 numLeaves) pure returns (uint256 pathLength) {
    // Get the height of the left subtree. This is equal to the offset of the starting bit of the path
    pathLength = 256 - getStartingBit(numLeaves);

    // Determine the number of leaves in the left subtree
    uint256 numLeavesLeftSubTree = (1 << (pathLength - 1));

    // If leaf is in left subtree, path length is full height of left subtree
    if (key <= numLeavesLeftSubTree - 1) {
        return pathLength;
    }
    // Otherwise, add 1 to height and recurse into right subtree
    else {
        return 1 + pathLengthFromKey(key - numLeavesLeftSubTree, numLeaves - numLeavesLeftSubTree);
    }
}

/// @notice Gets the bit at an offset from the most significant bit
/// @param data: The data to check the bit
/// @param position: The position of the bit to check
/// @return : The value of the bit
// solhint-disable-next-line func-visibility
function getBitAtFromMSB(bytes32 data, uint256 position) pure returns (uint256) {
    if (uint8(data[position / 8]) & (1 << (8 - 1 - (position % 8))) > 0) {
        return 1;
    } else {
        return 0;
    }
}

/// @notice Reverses an array
/// @param sideNodes: The array of sidenodes to be reversed
/// @return The reversed array
// solhint-disable-next-line func-visibility
function reverseSideNodes(bytes32[] memory sideNodes) pure returns (bytes32[] memory) {
    uint256 left = 0;
    uint256 right = sideNodes.length - 1;

    while (left < right) {
        (sideNodes[left], sideNodes[right]) = (sideNodes[right], sideNodes[left]);
        left = left + 1;
        right = right - 1;
    }
    return sideNodes;
}

/// @notice Shrinks an over-allocated dynamic array of bytes32 to the correct size
/// @param inputArray: The bytes32 array to be shrunk
/// @param length: The length to shrink to
/// @return finalArray : The full array of bytes32
/// @dev Needed where an unknown number of elements are to be pushed to a dynamic array
/// @dev We fist allocate a large-enough array, and then shrink once we're done populating it
// solhint-disable-next-line func-visibility
function shrinkBytes32Array(bytes32[] memory inputArray, uint256 length)
    pure
    returns (bytes32[] memory finalArray)
{
    finalArray = new bytes32[](length);
    for (uint256 i = 0; i < length; i++) {
        finalArray[i] = inputArray[i];
    }
    return finalArray;
}
