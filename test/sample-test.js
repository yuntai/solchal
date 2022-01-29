const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Challenge", function () {
  let token;
  let contractA;
  let contractB;
  let owner;
  let alice;
  let bob;

  beforeEach(async function() {
    [owner, bob, alice, ..._] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy("Token", "Token");
    await token.deployed();

    const ContractA = await ethers.getContractFactory("ContractA");
    contractA = await ContractA.deploy();
    await contractA.deployed();

    const ContractB = await ethers.getContractFactory("ContractB");
    contractB = await ContractB.deploy();
    await contractB.deployed();

    token.approve(bob.address, 10000);
    token.transfer(bob.address, 10000);

    token.approve(alice.address, 10000);
    token.transfer(alice.address, 10000);
  });

  it("contact A should be able to call contract B to update the data in contract B", async function() {
    await contractB.setA(contractA.address);
    await contractA.setB(contractB.address);

    await token.connect(bob).approve(contractA.address, 10000);
    await contractA.connect(bob).deposit(token.address, 1000)

    expect(await contractB.countRecord()).to.equal(1);
    let aRec = await contractB.getRecord(0);
    expect(aRec.user).to.equal(bob.address);
    expect(aRec.token).to.equal(token.address);
    expect(aRec.amount).to.equal(1000);
  });

  it("users of contract A should not have access to call contract B directly, this write functionality should be safeguarded", async function() {
    await expect(
      contractB.connect(alice).record(bob.address, token.address, 100)
    ).to.be.revertedWith("invalid writer");
  });

  it("contract B should only be writable by 1 admin user (the deployer) and contract A", async function() {
    const ContractA1 = await ethers.getContractFactory("ContractA");
    contractA1 = await ContractA1.deploy();
    await contractA1.deployed();

    await expect(
      contractB.connect(alice).record(bob.address, token.address, 100)
    ).to.be.revertedWith("invalid writer");

    await contractB.setA(contractA.address);
    await contractA.setB(contractB.address);

    await token.connect(bob).approve(contractA.address, 10000);
    await contractA.connect(bob).deposit(token.address, 1000)

    expect(await contractB.countRecord()).to.equal(1);

    await token.approve(contractA1.address, 10000);
    await contractA1.setB(contractB.address);
    await expect(
      contractA1.deposit(token.address, 1000)
    ).to.be.revertedWith("invalid writer");

    await contractB.setA(contractA1.address);

    await token.connect(alice).approve(contractA1.address, 10000);
    await contractA1.connect(alice).deposit(token.address, 1100);

    expect(await contractB.countRecord()).to.equal(2);
  });

  it("there should be a function in contract B that allows the admin to update the admin to a new address", async function() {
    await expect(
      contractB.connect(alice).changeAdmin(alice.address)
    ).to.be.revertedWith("Only admin");

    await contractB.changeAdmin(alice.address);
    const newAdmin = await contractB.admin();
    expect(newAdmin).to.equal(alice.address);
  });

  it("there should be a function in contract B that allows the admin to update contract A to a new address", async function() {
    await expect(
      contractB.connect(alice).setA(contractA.address)
    ).to.be.revertedWith("Only admin");

    await contractB.changeAdmin(alice.address);
    await contractB.connect(alice).setA(contractA.address);
    expect(await contractB.a()).to.equal(contractA.address);
  });

  it("there should be a function in contract A that allows the admin (deployer) to update contract B to a new address", async function() {
    await expect(
      contractA.connect(alice).setB(contractB.address)
    ).to.be.revertedWith("Only admin");

    await contractA.changeAdmin(alice.address);
    await contractA.connect(alice).setB(contractB.address);
    expect(await contractA.b()).to.equal(contractB.address);
  });
});
