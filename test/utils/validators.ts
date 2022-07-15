import { ethers } from 'hardhat';
import { Signer, Signature, utils } from 'ethers';
import hash from './cryptography';

// Sign a messag with a signer, returning the signature object (v, r, s components)
export async function componentSign(signer: Signer, message: string): Promise<Signature> {
	const flatSig = await signer.signMessage(ethers.utils.arrayify(message));
	const sig = ethers.utils.splitSignature(flatSig);
	return sig;
}

// Sign a message with as signer, returning a 64-byte compact ECDSA signature
export async function compactSign(signer: Signer, message: string): Promise<string> {
	const sig = await componentSign(signer, message);
	// eslint-disable-next-line no-underscore-dangle
	const compactSig = sig.r.concat(sig._vs.slice(2));
	return compactSig;
}

export function calculateValSetHash(validators: string[], stakes: number[]): string {
	return hash(utils.solidityPack(['address[]', 'uint256[]'], [validators, stakes]));
}
