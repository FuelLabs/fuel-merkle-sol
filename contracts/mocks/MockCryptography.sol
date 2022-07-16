// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {CryptographyLib} from "../Cryptography.sol";

contract MockCryptography {
    function hash(bytes memory data) public pure returns (bytes32) {
        return CryptographyLib.hash(data);
    }

    function addressFromSignatureComponents(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 message
    ) external pure returns (address) {
        return CryptographyLib.addressFromSignatureComponents(v, r, s, message);
    }

    function addressFromSignature(bytes memory signature, bytes32 message)
        external
        pure
        returns (address)
    {
        return CryptographyLib.addressFromSignature(signature, message);
    }
}
