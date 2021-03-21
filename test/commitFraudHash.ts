import chai from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Fuel } from "../typechain/Fuel";

chai.use(solidity);
const { expect } = chai;

describe("commitFraudHash", async () => {
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

        // Ensure it's finished deployment.
        await fuel.deployed();
    });

    it("commit a fraud hash", async () => {
        // Commit a fraud hash to chain.
        const fraudCommitment = ethers.utils.sha256('0xaa');
        const tx = await fuel.commitFraudHash(fraudCommitment);
        const receipt = await tx.wait();
        const committer = (await ethers.getSigners())[0].address;

        // Check if this fraud hash is there.
		expect(await fuel.s_FraudCommitments(
            committer,
            fraudCommitment,
        )).to.equal(receipt.blockNumber);
    });
});
