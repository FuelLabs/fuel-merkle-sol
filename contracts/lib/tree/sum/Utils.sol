// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../Constants.sol";

// solhint-disable-next-line func-visibility
function getStartingBit(uint256 numLeaves) pure returns (uint256 startingBit) {
    // Determine height of the left subtree. This is the maximum path length, so all paths start at this offset from the right-most bit
    startingBit = 0;
    while ((1 << startingBit) < numLeaves) {
        startingBit += 1;
    }
    return Constants.MAX_HEIGHT - startingBit;
}

// solhint-disable-next-line func-visibility
function pathLengthFromKey(uint256 key, uint256 numLeaves) pure returns (uint256 height) {
    // Get the height of the left subtree. This is equal to the offset of the starting bit of the path
    height = 256 - getStartingBit(numLeaves);

    // Determine the number of leaves in the left subtree
    uint256 numLeavesLeftSubTree = (1 << (height - 1));

    // If leaf is in left subtree, path length is full height of left subtree
    if (key <= numLeavesLeftSubTree - 1) {
        return height;
    }
    // Otherwise, add 1 to height and recurse into right subtree
    else {
        return 1 + pathLengthFromKey(key - numLeavesLeftSubTree, numLeaves - numLeavesLeftSubTree);
    }
}
