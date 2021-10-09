/// @dev The Fuel testing Merkle trees.
/// A set of useful helper methods for testing and deploying Merkle trees.
import { BigNumber as BN } from 'ethers';

export const EMPTY = '0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
export const ZERO = '0x0000000000000000000000000000000000000000000000000000000000000000';
export const MAX_HEIGHT = 256;

/// @dev Minimum transaction size in bytes.
export const TRANSACTION_SIZE_MIN = 44;

/// @dev Maximum transaction size in bytes.
export const TRANSACTION_SIZE_MAX = 21000;

/// @dev Empty leaf hash default value.
export const EMPTY_LEAF_HASH = ZERO;

/// @dev  Gas charged per byte of the transaction.
export const GAS_PER_BYTE = 1;

/// @dev Maximum gas per transaction.
export const MAX_GAS_PER_TX = 100_000;

/// @dev Maximum number of inputs.
export const MAX_INPUTS = 16;

/// @dev Maximum number of outputs.
export const MAX_OUTPUTS = 16;

/// @dev Maximum length of predicate, in instructions.
export const MAX_PREDICATE_LENGTH = 2400;

/// @dev Maximum length of predicate data, in bytes.
export const MAX_PREDICATE_DATA_LENGTH = 2400;

/// @dev Maximum length of script, in instructions.
export const MAX_SCRIPT_LENGTH = 2400;

/// @dev Maximum length of script, in instructions.
export const MAX_CONTRACT_LENGTH = 21000;

/// @dev Maximum length of script data, in bytes.
export const MAX_SCRIPT_DATA_LENGTH = 2400;

/// @dev Maximum number of static contracts.
export const MAX_STATIC_CONTRACTS = 255;

/// @dev  Max witnesses.
export const MAX_WITNESSES = 16;

// Does a util exist for this in ethers.js ?
export function uintToBytes32(i: number): string {
	const value = BN.from(i).toHexString();
	let trimmedValue = value.slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}

export function padUint(value: BN): string {
	// uint256 is encoded as 32 bytes, so pad that string.
	let trimmedValue = value.toHexString().slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}

// Does a util exist for this in ethers.js ?
export function padBytes(value: string): string {
	let trimmedValue = value.slice(2);
	trimmedValue = '0'.repeat(64 - trimmedValue.length).concat(trimmedValue);
	return '0x'.concat(trimmedValue);
}
