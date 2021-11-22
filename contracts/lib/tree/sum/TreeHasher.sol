// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../../../lib/Cryptography.sol";

/// @dev The prefixes of leaves and nodes, used to identify "nodes" as such.
bytes1 constant leafPrefix = 0x00;
bytes1 constant nodePrefix = 0x01;

/// @notice Hash a leaf node.
/// @param value fee of the leaf.
/// @param data, raw data of the leaf.
// solhint-disable-next-line func-visibility
function leafDigest(uint256 value, bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(abi.encodePacked(leafPrefix, value, data));
}

/// @notice Hash a node, which is not a leaf.
/// @param leftValue, sum of fees in left subtree.
/// @param left, left child hash.
/// @param right, right child hash.
// solhint-disable-next-line func-visibility
function nodeDigest(
    uint256 leftValue,
    bytes32 left,
    uint256 rightValue,
    bytes32 right
) pure returns (bytes32) {
    return CryptographyLib.hash(abi.encodePacked(nodePrefix, leftValue, left, rightValue, right));
}
