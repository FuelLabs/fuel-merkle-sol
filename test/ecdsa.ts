import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { BigNumber as BN, Contract, Signer } from 'ethers';
import { componentSign } from './utils/validators';

chai.use(solidity);
const { expect } = chai;

const SECP256K1N = BN.from('0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141');
const SIGNING_KEY = '0x0123456789012345678901234567890123456789012345678901234567890123';

describe('ECDSA', async () => {
	let mockCrypto: Contract;
	let signer: Signer;
	before(async () => {
		const mockCryptoFactory = await ethers.getContractFactory('MockCryptography');
		mockCrypto = await mockCryptoFactory.deploy();
		signer = new ethers.Wallet(SIGNING_KEY);
	});

	it('rejects component signatures with high s-value', async () => {
		const msg = ethers.utils.hexlify(ethers.utils.randomBytes(32));
		const sig = await componentSign(signer, msg);
		const vOrig = BN.from(sig.v).sub(27); // take v as 0 or 1

		// flip v and ensure it is 27 or 28
		const vFlipped = vOrig.xor(1).add(27);
		// flip s to secp256k1n - original s. This defines a unique
		// signature over the same data, which we want to reject.
		const sFlipped = SECP256K1N.sub(sig.s);
		const badSig = { v: vFlipped, r: sig.r, s: sFlipped };

		await expect(
			mockCrypto.addressFromSignatureComponents(badSig.v, badSig.r, badSig.s, msg)
		).to.be.revertedWith('signature-invalid-s');
	});

	it('rejects component signatures from the zero address', async () => {
		const msg = ethers.utils.hexlify(ethers.utils.randomBytes(32));
		const sig = await componentSign(signer, msg);
		// an r value < 1 makes the signature invalid. ecrecover will return 0x0
		const badSig = { v: sig.v, r: ethers.constants.HashZero, s: sig.s };

		await expect(
			mockCrypto.addressFromSignatureComponents(badSig.v, badSig.r, badSig.s, msg)
		).to.be.revertedWith('signature-invalid');
	});

	it('rejects invalid compact signatures', async () => {
		const msg = ethers.utils.hexlify(ethers.utils.randomBytes(32));
		const sig = await componentSign(signer, msg);

		// an r value < 1 makes the signature invalid. ecrecover will return 0x0
		const badRValue = ethers.constants.HashZero;
		// eslint-disable-next-line no-underscore-dangle
		const badSigCompact = badRValue.concat(sig._vs.slice(2));
		await expect(mockCrypto.addressFromSignature(badSigCompact, msg)).to.be.revertedWith(
			'signature-invalid'
		);

		// signature too short
		// eslint-disable-next-line no-underscore-dangle
		const shortSig = sig.r.concat(sig._vs.slice(4));
		await expect(mockCrypto.addressFromSignature(shortSig, msg)).to.be.revertedWith(
			'signature-invalid-length'
		);

		// signature too long
		// eslint-disable-next-line no-underscore-dangle
		const longSig = sig.r.concat(sig._vs.slice(2)).concat('aa');
		await expect(mockCrypto.addressFromSignature(longSig, msg)).to.be.revertedWith(
			'signature-invalid-length'
		);
	});
});
