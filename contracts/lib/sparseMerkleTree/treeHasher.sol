//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "../../lib/Cryptography.sol";
import "../constants.sol";

/// @notice Contains functions for hashing leaves and nodes, and parsing their data

/// @dev The prefixes of leaves and nodes, used to identify "nodes" as such.
bytes1 constant leafPrefix = 0x00;
bytes1 constant nodePrefix = 0x01;

/// @notice hash some data
/// @param data: The data to be hashed
// solhint-disable-next-line func-visibility
function hash(bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(data);
}

/// @notice Hash a leaf node.
/// @param key: The key of the leaf
/// @param data, raw data of the leaf.
// solhint-disable-next-line func-visibility
function hashLeaf(bytes32 key, bytes memory data) pure returns (bytes32, bytes memory) {
    bytes memory value = abi.encodePacked(leafPrefix, key, hash(data));
    return (hash(value), value);
}

/// @notice Hash a node, which is not a leaf.
/// @param left, left child hash.
/// @param right, right child hash.
// solhint-disable-next-line func-visibility
function hashNode(bytes32 left, bytes32 right) pure returns (bytes32, bytes memory) {
    bytes memory value = abi.encodePacked(nodePrefix, left, right);
    return (hash(value), value);
}

/// @notice Decode 65-byte node/leaf data to (bytes1, bytes32, bytes32)
/// @param _data: The node/leaf data to be decoded
// solhint-disable-next-line func-visibility
function decode(bytes memory _data)
    pure
    returns (
        bytes1 _a,
        bytes32 _b,
        bytes32 _c
    )
{
    uint256 o;
    assembly {
        let _la := 1
        let _lb := 32
        let _lc := 32

        let s := add(_data, 32)
        _a := mload(s)
        let l := sub(1, _la)
        if l {
            _a := div(_a, exp(2, mul(l, 8)))
        }

        o := add(s, _la)
        _b := mload(o)
        l := sub(32, _lb)
        if l {
            _b := div(_b, exp(2, mul(l, 8)))
        }

        o := add(o, _lb)
        _c := mload(o)
        l := sub(32, _lc)
        if l {
            _c := div(_c, exp(2, mul(l, 8)))
        }

        o := sub(o, s)
    }
    require(_data.length >= o, "Reading bytes out of bounds");
}

/// @notice Parse a node's data into its left and right children
/// @param data: The node data to be parsed
// solhint-disable-next-line func-visibility
function parseNode(bytes memory data) pure returns (bytes32, bytes32) {
    (, bytes32 left, bytes32 right) = decode(data);
    return (left, right);
}

/// @notice Parse a leaf's data into its key and data
/// @param data: The leaf data to be parsed
// solhint-disable-next-line func-visibility
function parseLeaf(bytes memory data) pure returns (bytes32, bytes32) {
    (, bytes32 key, bytes32 leafData) = decode(data);
    return (key, leafData);
}

/// @notice Inspect the prefix of a node's data to determine if it is a leaf
/// @param data: The data to be parsed
// solhint-disable-next-line func-visibility
function isLeaf(bytes memory data) pure returns (bool) {
    (bytes1 prefix, , ) = decode(data);
    return (prefix == leafPrefix);
}
