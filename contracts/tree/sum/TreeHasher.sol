// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../Cryptography.sol";
import "../Constants.sol";

/// @notice Hash a leaf node.
/// @param value fee of the leaf.
/// @param data, raw data of the leaf.
// solhint-disable-next-line func-visibility
function leafDigest(uint256 value, bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(abi.encodePacked(Constants.LEAF_PREFIX, value, data));
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
    return
        CryptographyLib.hash(
            abi.encodePacked(Constants.NODE_PREFIX, leftValue, left, rightValue, right)
        );
}
