import chai from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Fuel } from "../typechain/Fuel";
import { Token } from "../typechain/Token";

chai.use(solidity);
const { expect } = chai;

describe("deposit", async () => {
    // The Fuel.
    let fuel: Fuel;

    // Constructor Arguments.
    const finalizationDelay = 100;
    const bond = ethers.utils.parseEther('1.0');
    const name = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes("Fuel"), 32);
    const version = ethers.utils.hexZeroPad(ethers.utils.toUtf8Bytes("v2.0"), 32);

    // Token.
    let token: Token;

    // Signer.
    let signer = "";

    // Initial token amount
    const initialTokenAmount = ethers.utils.parseEther('1000');

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

        // Deploy a token for deposit testing.
        const tokenFactory = await ethers.getContractFactory("Token");

        // Deploy token.
        token = (await tokenFactory.deploy()) as Token;

        // Ensure it's finished deployment.
        await token.deployed();

        // Set signer.
        signer = (await ethers.getSigners())[0].address;

        // Mint token to the first signer.
        await token.mint(signer, initialTokenAmount);
    });

    it("check token balance", async () => {
        expect(await token.balanceOf(signer)).to.be.equal(initialTokenAmount);
    });

    it("make a deposit with the token", async () => {
        // Approve the Fuel contract.
        await token.approve(fuel.address, initialTokenAmount);

        // Make a deposit.
        await fuel.deposit(signer, token.address, initialTokenAmount);

        // Check the balance of the Fuel contract.
        expect(await token.balanceOf(signer)).to.be.equal(0);
        expect(await token.balanceOf(fuel.address)).to.be.equal(initialTokenAmount);
    });
});
