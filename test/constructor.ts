import chai from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Fuel } from "../typechain/Fuel";

chai.use(solidity);
const { expect } = chai;

describe("constructor", async () => {
	// The Fuel.
	let fuel: Fuel;

	// Constructor Arguments.
	const finalizationDelay = 100;
	const bond = ethers.utils.parseEther('1.0');
	const name = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes("Fuel"), 32);
	const version = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes("v2.0"), 32);

	// Nice setup.
	beforeEach(async () => {
		// Factory.
		const fuelFactory = await ethers.getContractFactory("Fuel");

		// Deployment.
		fuel = (await fuelFactory.deploy(
			finalizationDelay,
			bond,
			name,
			version,
		)) as Fuel;

		// Ensure it's deployed.
		await fuel.deployed();
	});

	it("should construct nicely", async () => {
		expect(await fuel.BOND_SIZE()).to.equal(bond);
		expect(await fuel.FINALIZATION_DELAY()).to.equal(finalizationDelay);
		expect(await fuel.NAME()).to.equal(name);
		expect(await fuel.VERSION()).to.equal(version);
		expect(await fuel.s_BlockTip()).to.equal(0);
	});
});
