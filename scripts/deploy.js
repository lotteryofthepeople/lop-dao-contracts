const { ethers } = require("hardhat");

const minVotePercent = 5; // 5%
const ERC20LOPContractAddress = "0x18c4195401b119780DFc0361B19a8e563202399B";
const ERC20VLOPContractAddress = "0x428C18e3403EDA161D04B55982625e9C19b5a049";
const UsdcContractAddress = "0x9FC58C925ADf1163fEE5Cd1d56e5e550624c2d91";

async function main() {
  // const lopFactory = await ethers.getContractFactory("ERC20LOP");
  // const lopContract = await lopFactory.deploy(
  //   ethers.utils.parseEther("10000000")
  // );

  // const vLopFactory = await ethers.getContractFactory("ERC20VLOP");
  // const vLopContract = await vLopFactory.deploy(
  //   ethers.utils.parseEther("10000000")
  // );
  // console.log("ERC20LOP===>", lopContract.address);
  // console.log("ERC20VLOP===>", vLopContract.address);

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
