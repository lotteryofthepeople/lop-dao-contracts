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

  console.log("ERC20LOPContractContract: ", ERC20LOPContract.address);
  console.log("ERC20VLOPContractContract: ", ERC20VLOPContract.address);
  console.log("ShareHolderDaoContract: ", shareHolderDaoContract.address);
}

main();
