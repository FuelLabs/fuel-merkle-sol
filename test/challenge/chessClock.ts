import chai from 'chai';
import { solidity } from 'ethereum-waffle';
import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import ClockState from '../../protocol/challenge/types/clock';

chai.use(solidity);
const { expect } = chai;

function advanceToTime(timeStamp: number) {
	ethers.provider.send('evm_setNextBlockTimestamp', [timeStamp]);
}

describe('Chess clock [ @skip-on-coverage ]', async () => {
	let clockTest: Contract;
	let clockState: ClockState;
	let lastFlipped: number;

	const clockTime = 1000;

	before(async () => {
		const chessClockLibTestFactory = await ethers.getContractFactory('ChessClockLib');
		const chessClockLib = await chessClockLibTestFactory.deploy();
		await chessClockLib.deployed();

		const clockTestFactory = await ethers.getContractFactory('ClockTest', {
			libraries: { ChessClockLib: chessClockLib.address },
		});
		clockTest = await clockTestFactory.deploy(clockTime);
		await clockTest.deployed();
	});

	it('Should be initialized', async () => {
		clockState = await clockTest.clock();
		lastFlipped = clockState.lastFlipped.toNumber();

		expect(Math.floor(Date.now() / 1000) - lastFlipped).to.be.lte(10);
		expect(clockState.position).to.equal(0);
		expect(await clockTest.state()).to.equal('game begins');
	});

	it('Manual time-out should revert: player in time', async () => {
		await expect(clockTest.timeOut()).to.be.revertedWith('ChessClock/time not up');
	});

	it('Should be in time amd flip the state', async () => {
		advanceToTime(lastFlipped + clockTime / 2);
		clockState = await clockTest.clock();

		// "Tick" should still have half the total time on their clock, so game should continue
		await clockTest.flip();
		clockState = await clockTest.clock();
		lastFlipped = clockState.lastFlipped.toNumber();
		expect(await clockTest.state()).to.equal('game continues...');
		expect(clockState.position).to.equal(1);
	});

	it('Should be out of time: automatic timeOut', async () => {
		advanceToTime(lastFlipped + clockTime + 1);
		clockState = await clockTest.clock();

		// "Tock" should have more than total time on their clock, so Tick should win
		await clockTest.flip();
		clockState = await clockTest.clock();
		expect(await clockTest.state()).to.equal('Tock timed out: tick wins!');
		lastFlipped = clockState.lastFlipped.toNumber();
	});

	it('Should be reset', async () => {
		expect(Math.floor(Date.now() / 1000) - lastFlipped).to.be.lte(10);
		expect(clockState.position).to.equal(0);
	});

	it('Should be out of time: manual timeOut', async () => {
		advanceToTime(lastFlipped + clockTime + 1);
		clockState = await clockTest.clock();

		// "Tick" should have more than total time on their clock, so Tock should win
		await clockTest.timeOut();
		clockState = await clockTest.clock();
		expect(await clockTest.state()).to.equal('Tick timed out: tock wins!');
	});
});
