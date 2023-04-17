const { ethers } = require("hardhat");
const { expect } = require("chai");

const initialSupply = ethers.utils.parseEther("100000");

describe("LOP TestCase", () => {
  before(async () => {
    [owner, addr1, addr2, addr3, addr4, addr4, addr5, ...addrs] =
      await ethers.getSigners();

    erc20LOPFactory = await ethers.getContractFactory("ERC20LOP");
    erc20VLOPFactory = await ethers.getContractFactory("ERC20VLOP");

    erc20LOPContract = await erc20LOPFactory
      .connect(owner)
      .deploy(initialSupply);
    erc20VLOPContract = await erc20VLOPFactory
      .connect(owner)
      .deploy(initialSupply);
  });

  describe("Check ERC20LOP contract", () => {
    it("set token name as `Lottery of the People`", async () => {
      expect(await erc20LOPContract.name()).to.be.equal(
        "Lottery of the People"
      );
    });

    it("set token symbol as `LOP`", async () => {
      expect(await erc20LOPContract.symbol()).to.be.equal("LOP");
    });

    it("mint token as `initialSupply`", async () => {
      expect(await erc20LOPContract.totalSupply()).to.be.equal(initialSupply);
    });

    it("set contract deployer as minter", async () => {
      expect(await erc20LOPContract.isMinter(owner.address)).to.be.equal(true);
    });

    it("only owner can set minter", async () => {
      expect(
        erc20LOPContract.connect(addr1).addMinter(addr2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("set minter", async () => {
      await erc20LOPContract.connect(owner).addMinter(addr1.address);
      expect(await erc20LOPContract.isMinter(addr1.address)).to.be.equal(true);
    });

    it("remove minter", async () => {
      await erc20LOPContract.connect(owner).removeMinter(addr1.address);
      expect(await erc20LOPContract.isMinter(addr1.address)).to.be.equal(false);
    });
  });

  describe("Check ERC20VLOP contract", () => {
    it("set token name as `Lottery of the People`", async () => {
      expect(await erc20VLOPContract.name()).to.be.equal(
        "Lottery of the People"
      );
    });

    it("set token symbol as `vLOP`", async () => {
      expect(await erc20VLOPContract.symbol()).to.be.equal("vLOP");
    });

    it("mint token as `initialSupply`", async () => {
      expect(await erc20VLOPContract.totalSupply()).to.be.equal(initialSupply);
    });

    it("set contract deployer as minter", async () => {
      expect(await erc20VLOPContract.isMinter(owner.address)).to.be.equal(true);
    });

    it("only owner can set minter", async () => {
      expect(
        erc20VLOPContract.connect(addr1).addMinter(addr2.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("set minter", async () => {
      await erc20VLOPContract.connect(owner).addMinter(addr1.address);
      expect(await erc20VLOPContract.isMinter(addr1.address)).to.be.equal(true);
    });

    it("remove minter", async () => {
      await erc20VLOPContract.connect(owner).removeMinter(addr1.address);
      expect(await erc20VLOPContract.isMinter(addr1.address)).to.be.equal(
        false
      );
    });
  });
});
