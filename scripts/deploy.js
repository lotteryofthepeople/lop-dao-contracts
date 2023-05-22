const { ethers } = require("hardhat");

const minVotePercent = 5; // 5%
const ERC20LOPContractAddress = "0x421C8727370aFA82Cb1b8Da97d3C10B31361A004";
const ERC20VLOPContractAddress = "0x0584C994824b93FfE675d09aEA823Fe97Fa4ef98";
const UsdcContractAddress = "0x9FC58C925ADf1163fEE5Cd1d56e5e550624c2d91";

async function main() {
  const StakingFactory = await ethers.getContractFactory("Staking");
  const stakingContract = await StakingFactory.deploy(
    ERC20LOPContractAddress,
    ERC20VLOPContractAddress,
    minVotePercent
  );

  const ShareHolderDaoFactory = await ethers.getContractFactory(
    "ShareHolderDao"
  );
  const shareHolderDaoContract = await ShareHolderDaoFactory.deploy(
    stakingContract.address
  );

  productDaoFactory = await ethers.getContractFactory("ProductDao");
  productDaoContract = await productDaoFactory.deploy(stakingContract.address);

  developmentDaoFactory = await ethers.getContractFactory("DevelopmentDao");
  developmentDaoContract = await developmentDaoFactory.deploy(
    shareHolderDaoContract.address,
    productDaoContract.address,
    stakingContract.address
  );

  const TreasuryDaoFactory = await ethers.getContractFactory("TreasuryDao");
  const treasuryDaoContract = await TreasuryDaoFactory.deploy(
    UsdcContractAddress,
    stakingContract.address
  );

  console.log("StakingContract: ", stakingContract.address);
  console.log("ShareHolderDaoContract: ", shareHolderDaoContract.address);
  console.log("ProductDaoContract: ", productDaoContract.address);
  console.log("DevelopmentDaoContract: ", developmentDaoContract.address);
  console.log("TreasuryDaoContract: ", treasuryDaoContract.address);
}

main();
