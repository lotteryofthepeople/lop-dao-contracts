const { ethers } = require("hardhat");

const totalSupply = ethers.utils.parseEther("10000000");
const minVotePercent = 5; // 5%

async function main() {
  const ERC20LOPFactory = await ethers.getContractFactory("ERC20LOP");
  const ERC20LOPContract = await ERC20LOPFactory.deploy(totalSupply);

  const ERC20VLOPFactory = await ethers.getContractFactory("ERC20VLOP");
  const ERC20VLOPContract = await ERC20VLOPFactory.deploy(totalSupply);

  const ShareHolderDaoFactory = await ethers.getContractFactory(
    "ShareHolderDao"
  );
  const shareHolderDaoContract = await ShareHolderDaoFactory.deploy(
    ERC20LOPContract.address,
    ERC20VLOPContract.address,
    minVotePercent
  );

  usdcFactory = await ethers.getContractFactory("USDC");
  usdcContract = await usdcFactory.deploy();

  const TreasuryDaoFactory = await ethers.getContractFactory("TreasuryDao");
  const treasuryDaoContract = await TreasuryDaoFactory.deploy(
    usdcContract.address,
    shareHolderDaoContract.address
  );

  productDaoFactory = await ethers.getContractFactory("ProductDao");
  productDaoContract = await productDaoFactory.deploy(
    shareHolderDaoContract.address
  );

  developmentDaoFactory = await ethers.getContractFactory("DevelopmentDao");
  developmentDaoContract = await developmentDaoFactory.deploy(
    shareHolderDaoContract.address,
    productDaoContract.address
  );

  console.log("ERC20LOPContractContract: ", ERC20LOPContract.address);
  console.log("ERC20VLOPContractContract: ", ERC20VLOPContract.address);
  console.log("UsdcContract: ", usdcContract.address);
  console.log("ShareHolderDaoContract: ", shareHolderDaoContract.address);
  console.log("TreasuryDaoContract: ", treasuryDaoContract.address);
  console.log("ProductDaoContract: ", productDaoContract.address);
  console.log("DevelopmentDaoContract: ", developmentDaoContract.address);
}

main();
