import chai from "chai";
import { solidity } from "ethereum-waffle";
import { HarnessObject, setupFuel } from "../protocol/harness";

chai.use(solidity);
const { expect } = chai;

describe("deposit", async () => {
  let env: HarnessObject;

  beforeEach(async () => {
    env = await setupFuel({});
  });

  it("check token balance", async () => {
    expect(await env.token.balanceOf(env.signer)).to.be.equal(
      env.initialTokenAmount
    );
  });

  it("make a deposit with the token", async () => {
    // Approve the Fuel contract.
    await env.token.approve(env.fuel.address, env.initialTokenAmount);

    // Make a deposit.
    await env.fuel.deposit(
      env.signer,
      env.token.address,
      env.initialTokenAmount
    );

    // Check the balance of the Fuel contract.
    expect(await env.token.balanceOf(env.signer)).to.be.equal(0);
    expect(await env.token.balanceOf(env.fuel.address)).to.be.equal(
      env.initialTokenAmount
    );
  });
});
