import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { HarnessObject, setupFuel } from '../protocol/harness';

chai.use(solidity);
const { expect } = chai;

describe('burnAuction', async () => {
	let env: HarnessObject;

	before(async () => {
		env = await setupFuel({});
	});

	it('Check Deployments', async () => {
		// Check burnAuction is authorized to call mint on FuelToken
		const sig = ethers.utils.id('mint(address,uint256)').slice(0, 10);
		expect(await env.guard.canCall(env.burnAuction.address, env.fuelToken.address, sig));

		// Check nobody else can call mint on FuelToken
		await expect(
			env.fuelToken.connect(env.signers[1]).functions['mint(address,uint256)'](env.signer, 1)
		).to.be.revertedWith('ds-auth-unauthorized');
	});

	it('Place first bid', async () => {
		const auc = env.burnAuction;

		// Get state before bid
		const bidderBalance = await ethers.provider.getBalance(env.signer);

		// Place bid of 1 ether
		const bid = ethers.utils.parseEther('1.0');
		await env.burnAuction.placeBid({ value: bid });

		// Check new bidder, bid, and bid expiry
		expect(await auc.highestBidder()).to.be.equal(env.signer);
		expect(await auc.highestBid()).to.be.equal(bid);
		expect(await ethers.provider.getBalance(env.signer)).to.be.lt(bidderBalance.sub(bid));
	});

	it('Place a new highest bid, as plain ether transaction', async () => {
		const auc = env.burnAuction;

		// Get state before bid
		const bidderBalance = await ethers.provider.getBalance(env.addresses[1]);

		// Place bid of 2 ether from second address
		const bid = ethers.utils.parseEther('2.0');

		const tx = {
			to: auc.address,
			value: bid,
			gasLimit: 50000,
			gasPrice: 100000000000,
		};
		await env.signers[1].sendTransaction(tx);

		// Check new bidder, bid, and bid expiry
		expect(await auc.highestBidder()).to.be.equal(env.addresses[1]);
		expect(await auc.highestBid()).to.be.equal(bid);
		expect(await ethers.provider.getBalance(env.addresses[1])).to.be.lt(bidderBalance.sub(bid));
	});

	it('Try to place a bid lower than the higehst bid, expect revert', async () => {
		const bid = ethers.utils.parseEther('1.5');
		await expect(
			env.burnAuction.connect(env.signers[3]).placeBid({ value: bid })
		).to.be.revertedWith('FuelAuction/Bid-not-higher');
	});

	it('Try to end auction too early, expect revert', async () => {
		await expect(env.burnAuction.endAuction()).to.be.revertedWith(
			'FuelAuction/Auction-not-finished'
		);
	});

	it('Fast-forward to auction end, try to place late bid. Expect revert', async () => {
		const auc = env.burnAuction;
		const AUCTION_DURATION = (await auc.AUCTION_DURATION()).toNumber();

		// Fast-forward to end of auction
		ethers.provider.send('evm_increaseTime', [AUCTION_DURATION]);

		const bid = ethers.utils.parseEther('3.0');
		await expect(env.burnAuction.placeBid({ value: bid })).to.be.revertedWith(
			'FuelAuction/Auction-finshed'
		);
	});

	it('Settle auction (burn funds and pay winner) and reset auction state', async () => {
		const auc = env.burnAuction;

		const winner = await auc.highestBidder();
		const lotSize = await auc.LOT_SIZE();

		// End auction
		await auc.endAuction();

		// Check winner was paid
		expect(await env.fuelToken.balanceOf(winner)).to.be.equal(lotSize);

		// Check state is reset
		expect(await auc.highestBidder()).to.be.equal(ethers.constants.AddressZero);
		expect(await auc.highestBid()).to.be.equal(0);
	});

	// Tests a griefing vector where attacker can prevent any future bids :
	// https://github.com/FuelLabs/fuel-v2-contracts/issues/34
	it('Should not be griefable', async () => {
		const Griefer = await ethers.getContractFactory('BurnAuctionGriefer');
		const auc = env.burnAuction;
		const g = await Griefer.deploy(auc.address);

		const bid = (await auc.highestBid()).add(ethers.utils.parseEther('1.0'));
		await g.grief({ value: bid });
		expect(await auc.highestBidder()).to.be.equal(g.address);

		const newBid = bid.add(ethers.utils.parseEther('1.0'));
		await expect(env.burnAuction.placeBid({ value: newBid })).to.not.be.reverted;
		expect(await auc.highestBidder()).to.be.equal(env.addresses[0]);
	});
});
