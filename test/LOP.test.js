const { ethers } = require("hardhat");
const { expect } = require("chai");

const initialSupply = ethers.utils.parseEther("100000");
const minVotePercent = 65;
const proposalAmount = ethers.utils.parseEther("1.5");

const ProposalStatus = {
  NONE: 0,
  CREATED: 1,
  CANCELLED: 2,
  ACTIVE: 3,
};

describe("LOP TestCase", () => {
  before(async () => {
    [owner, addr1, addr2, addr3, addr4, addr4, addr5, ...addrs] =
      await ethers.getSigners();

    erc20LOPFactory = await ethers.getContractFactory("ERC20LOP");
    erc20VLOPFactory = await ethers.getContractFactory("ERC20VLOP");
    shareHolderDaoFactory = await ethers.getContractFactory("ShareHolderDao");
    productDaoFactory = await ethers.getContractFactory("ProductDao");
    usdcFactory = await ethers.getContractFactory("USDC");
    treasuryDaoFactory = await ethers.getContractFactory("TreasuryDao");

    erc20LOPContract = await erc20LOPFactory
      .connect(owner)
      .deploy(initialSupply);

    erc20VLOPContract = await erc20VLOPFactory
      .connect(owner)
      .deploy(initialSupply);

    shareHolderContract = await shareHolderDaoFactory
      .connect(owner)
      .deploy(
        erc20LOPContract.address,
        erc20VLOPContract.address,
        minVotePercent
      );

    productDaoContract = await productDaoFactory
      .connect(owner)
      .deploy(shareHolderContract.address);

    usdcContract = await usdcFactory.connect(owner).deploy();

    treasuryDaoContract = await treasuryDaoFactory
      .connect(owner)
      .deploy(usdcContract.address, shareHolderContract.address);
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

  describe("Check ShareHolderDao contract", async () => {
    it("check LOP address", async () => {
      expect(await shareHolderContract.getLOP()).to.be.equal(
        erc20LOPContract.address
      );
    });

    it("check vLOP address", async () => {
      expect(await shareHolderContract.getVLOP()).to.be.equal(
        erc20VLOPContract.address
      );
    });

    it("check getMinVotePercent", async () => {
      expect(await shareHolderContract.getMinVotePercent()).to.be.equal(
        minVotePercent
      );
    });

    describe("Check `createProposal`", () => {
      it("only token holder can create a new proposal", async () => {
        expect(
          shareHolderContract.connect(addr1).createProposal(proposalAmount)
        ).to.be.revertedWith(
          "ShareHolderDao: You have not enough LOP or vLOP token"
        );
      });

      it("check create a new proposal with event", async () => {
        await expect(
          shareHolderContract.connect(owner).createProposal(proposalAmount)
        )
          .to.emit(shareHolderContract, "ProposalCreated")
          .withArgs(owner.address, proposalAmount, 0);
      });

      it("check share info after create a new proposal", async () => {
        expect(await shareHolderContract.proposalIndex()).to.be.equal(1);
        const _shareInfo = await shareHolderContract.getShareHolderInfoByUser(
          owner.address
        );
        expect(_shareInfo.created).to.be.equal(true);
        expect(_shareInfo.budget).to.be.equal(proposalAmount);
      });

      it("check proposal info after create a new proposal", async () => {
        const _proposal = await shareHolderContract.proposals(0);
        expect(_proposal.budget).to.be.equal(proposalAmount);
        expect(_proposal.owner).to.be.equal(owner.address);
        expect(_proposal.status).to.be.equal(ProposalStatus.CREATED);
        expect(_proposal.voteYes).to.be.equal(0);
        expect(_proposal.voteNo).to.be.equal(0);
      });

      it("only one proposal should be active now", async () => {
        expect(
          shareHolderContract.connect(owner).createProposal(proposalAmount)
        ).to.be.revertedWith("ShareHolderDao: Your proposal is active now");
      });
    });

    describe("Check `voteYes`", () => {
      it("only token holder can voteYes", async () => {
        expect(
          shareHolderContract.connect(addr1).voteYes(0)
        ).to.be.revertedWith(
          "ShareHolderDao: You have not enough LOP or vLOP token"
        );
      });
    });

    describe("Check `voteNo`", () => {
      it("only token holder can voteNo", async () => {
        expect(shareHolderContract.connect(addr1).voteNo(0)).to.be.revertedWith(
          "ShareHolderDao: You have not enough LOP or vLOP token"
        );
      });
    });
  });

  describe("Check ProductDao contract", async () => {
    it("set shareHolderDao address correctly", async () => {
      expect(await productDaoContract.shareHolderDao()).to.be.equal(
        shareHolderContract.address
      );
    });

    it("check createProposal", async () => {
      const _testMetaData = "test metadata";
      await productDaoContract.connect(owner).createProposal(_testMetaData);
      expect(
        await productDaoContract.proposalStatus(owner.address)
      ).to.be.equal(ProposalStatus.CREATED);
      expect(await productDaoContract.proposalIndex()).to.be.equal(1);
      const _proposalInfo = await productDaoContract.getProposalById(0);
      expect(_proposalInfo.metadata).to.be.equal(_testMetaData);
      expect(_proposalInfo.status).to.be.equal(ProposalStatus.CREATED);
      expect(_proposalInfo.owner).to.be.equal(owner.address);
      expect(_proposalInfo.voteYes).to.be.equal(0);
      expect(_proposalInfo.voteNo).to.be.equal(0);
    });

    it("check voteYes", async () => {
      await productDaoContract.connect(owner).voteYes(0);
      expect(await productDaoContract.isVoted(owner.address, 0)).to.be.equal(
        true
      );
    });

    it("check voteNo", async () => {
      await erc20LOPContract
        .connect(owner)
        .transfer(addr1.address, ethers.utils.parseEther("1"));

      const _testMetaData = "test metadata";
      await productDaoContract.connect(addr1).createProposal(_testMetaData);
      await productDaoContract.connect(addr1).voteNo(1);
      expect(await productDaoContract.isVoted(addr1.address, 1)).to.be.equal(
        true
      );
    });

    it("check execute", async () => {
      await productDaoContract.connect(owner).execute(0);
      const _proposalInfo = await productDaoContract.getProposalById(0);
      expect(_proposalInfo.status).to.be.equal(ProposalStatus.ACTIVE);
    });
  });

  describe("Check TreasuryDao contract", async () => {
    it("set usdc contract", async () => {
      expect(await treasuryDaoContract.USDC()).to.be.equal(
        usdcContract.address
      );
    });

    it("set shareholder dao address", async () => {
      expect(await treasuryDaoContract.shareHolderDao()).to.be.equal(
        shareHolderContract.address
      );
    });

    it("check depositLOP", async () => {
      await erc20LOPContract
        .connect(owner)
        .approve(treasuryDaoContract.address, ethers.utils.parseEther("1"));

      await treasuryDaoContract
        .connect(owner)
        .depositLOP(ethers.utils.parseEther("1"));

      expect(
        await erc20LOPContract.balanceOf(treasuryDaoContract.address)
      ).to.be.equal(ethers.utils.parseEther("1"));
    });

    it("check depositUsdc", async () => {
      await usdcContract
        .connect(owner)
        .approve(treasuryDaoContract.address, ethers.utils.parseEther("1"));

      await treasuryDaoContract
        .connect(owner)
        .depositUsdc(ethers.utils.parseEther("1"));

      expect(
        await usdcContract.balanceOf(treasuryDaoContract.address)
      ).to.be.equal(ethers.utils.parseEther("1"));
    });

    it("check setSwapStatus", async () => {
      await treasuryDaoContract.connect(owner).setSwapStatus(true);
      expect(await treasuryDaoContract.swapStatus()).to.be.equal(true);
    });

    it("check swapLopToUsdc", async () => {
      const amount = "0.5";
      await erc20LOPContract
        .connect(owner)
        .approve(treasuryDaoContract.address, ethers.utils.parseEther(amount));

      const beforeTreasuryBalance = await erc20LOPContract.balanceOf(
        treasuryDaoContract.address
      );

      await treasuryDaoContract
        .connect(owner)
        .swapLopToUsdc(ethers.utils.parseEther(amount));

      const afterTreasuryBalance = await erc20LOPContract.balanceOf(
        treasuryDaoContract.address
      );

      expect(afterTreasuryBalance.sub(beforeTreasuryBalance)).to.be.equal(
        ethers.utils.parseEther(amount)
      );

      expect(
        await usdcContract.balanceOf(treasuryDaoContract.address)
      ).to.be.equal(ethers.utils.parseEther(amount));
    });

    it("check swapUsdcToLop", async () => {
      const amount = "0.5";
      await usdcContract
        .connect(owner)
        .approve(treasuryDaoContract.address, ethers.utils.parseEther(amount));

      const beforeUsdcBalance = await usdcContract.balanceOf(
        treasuryDaoContract.address
      );
      const beforeLopBalance = await erc20LOPContract.balanceOf(
        treasuryDaoContract.address
      );

      await treasuryDaoContract
        .connect(owner)
        .swapUsdcToLop(ethers.utils.parseEther(amount));

      const afterUsdcBalance = await usdcContract.balanceOf(
        treasuryDaoContract.address
      );

      const afterLopBalance = await erc20LOPContract.balanceOf(
        treasuryDaoContract.address
      );

      expect(afterUsdcBalance.sub(beforeUsdcBalance)).to.be.equal(
        ethers.utils.parseEther(amount)
      );
      expect(beforeLopBalance.sub(afterLopBalance)).to.be.equal(
        ethers.utils.parseEther(amount)
      );
    });
  });
});
