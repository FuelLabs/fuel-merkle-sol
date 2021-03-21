import chai from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Fuel } from "../typechain/Fuel";
import { 
    computeCommitmentHash,
    computeDigestCommitmentHash,
    computeBlockId,
    computeTransactionsLength,
    EMPTY_BLOCK_ID,
    BlockHeader,
} from '../protocol/block';

chai.use(solidity);
const { expect } = chai;

describe("bondWithdraw", async () => {
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

    it("produce a block", async () => {
        // Block properties.
        const producer = (await ethers.getSigners())[0].address;
        const minimum = await ethers.provider.getBlockNumber();
        const minimumBlock = await ethers.provider.getBlock(minimum);;
        const minimumHash = minimumBlock.hash;
        const height = 0;
        const previousBlockHash = EMPTY_BLOCK_ID;
        const merkleTreeRoot = ethers.utils.sha256('0xdeadbeaf');
        const transactions = ethers.utils.hexZeroPad('0x', 500);
        const digestMerkleRoot = ethers.utils.sha256('0xdeadbeaf');
        const digests = [
            ethers.utils.hexZeroPad('0xdead', 32),
            ethers.utils.hexZeroPad('0xbeaf', 32),
            ethers.utils.hexZeroPad('0xdeed', 32),
        ];

        // Commit block to chain.
        let tx = await fuel.commitBlock(
            minimum,
            minimumHash,
            height,
            previousBlockHash,
            merkleTreeRoot,
            transactions,
            digestMerkleRoot,
            digests,
            {
                value: bond,
            },
        );
        const receipt = await tx.wait();
        const blockNumber = receipt.blockNumber;

        const blockHeader:BlockHeader = {
            producer,
            previousBlockHash,
            height,
            blockNumber,
            digestCommitmentHash: computeDigestCommitmentHash(digests),
            digestMerkleRoot,
            digestLength: digests.length,
            merkleTreeRoot,
            commitmentHash: computeCommitmentHash(transactions),
            length: computeTransactionsLength(transactions),
        };

        // Compute the block id.
        const blockHash = computeBlockId(blockHeader);

        // Check for correctness.
		expect(await fuel.getBlockCommitmentChild(
            previousBlockHash,
            0,
        )).to.equal(blockHash);
		expect(await fuel.getBlockCommitmentNumChildren(
            previousBlockHash,
        )).to.equal(1);

        // Mine finalization delay.
        for (let i = 0; i < finalizationDelay; i++) {
            await ethers.provider.send('evm_mine', []);
        }

        // Pre balance of bond poster.
        const preBalance = await ethers.provider.getBalance(producer);

        // Retrieve the bond.
        const withdrawTx = await fuel.bondWithdraw(blockHeader);
        const withdrawReceipt = await withdrawTx.wait();

        // Post balance.
        const postBalance = await ethers.provider.getBalance(producer);

        // Look for an increase in balance.
        const gasUsed = withdrawReceipt.cumulativeGasUsed
            .mul(withdrawTx.gasPrice);

        // Check increase in balance.
        expect(postBalance).to.equal(preBalance.add(bond).sub(gasUsed));
    });
});
