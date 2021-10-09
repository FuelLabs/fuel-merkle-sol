// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "../lib/challenge/TransactionSerializationLib.sol";

contract TxSerialization {
    using TransactionSerializationLib for Transaction;

    bytes public result;

    function serialize(Transaction memory t, bool compressed) public returns (bool success) {
        result = t.serializeTransaction(compressed);
        success = true;
    }
}
