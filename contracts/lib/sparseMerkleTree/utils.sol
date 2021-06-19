//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "./treeHasher.sol";
import "./proofs.sol";
import "../constants.sol";

/// @notice Contains utility functions for sparse merkle trees

/// @notice A struct for holding a pair of siblings
/// @dev This abstraction introduced to reduce too many intermediate variables
/// @dev causing stack-too-deep compiler errors
struct NodePair {
    bytes32 nodeHash;
    bytes32 sideNode;
}

/// @notice Gets the bit at an offset from the most significant bit
/// @param data: The data to check the bit
/// @param position: The position of the bit to check
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

/// @notice Counts the number of leading bits two bytes32 have in common
/// @param data1: The first piece of data to compare
/// @param data2: The second piece of data to compare
/// @return The number of shared leading bits
// solhint-disable-next-line func-visibility
function countCommonPrefix(bytes32 data1, bytes32 data2) pure returns (uint256) {
    uint256 count = 0;

    for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
        if (getBitAtFromMSB(data1, i) == getBitAtFromMSB(data2, i)) {
            count += 1;
        } else {
            break;
        }
    }
    return count;
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

/// @notice Shrinks an over-allocated dynamic array of Updates to the correct size
/// @param inputArray: The Updates array to be shrunk
/// @param length: The length to shrink to
/// @return finalArray : The full array of updates
/// @dev Needed where an unknown number of elements are to be pushed to a dynamic array
/// @dev We fist allocate a large-enough array, and then shrink once we're done populating it
// solhint-disable-next-line func-visibility
function shrinkUpdatesArray(UpdateFromProof[] memory inputArray, uint256 length)
    pure
    returns (UpdateFromProof[] memory finalArray)
{
    finalArray = new UpdateFromProof[](length);
    for (uint256 i = 0; i < length; i++) {
        finalArray[i] = inputArray[i];
    }
    return finalArray;
}

/// @notice compares a byte array to the (bytes32) default (ZERO) value
/// @param value : The bytes to compare
/// @dev No byte array comparison in solidity, so compare keccak hashes
// solhint-disable-next-line func-visibility
function isDefaultValue(bytes memory value) pure returns (bool) {
    return keccak256(value) == keccak256(abi.encodePacked(Constants.ZERO));
}
