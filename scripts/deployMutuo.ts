import { ethers } from "hardhat";

async function main() {
  
  const MUTUO = await ethers.getContractFactory("InvestStartup");
  const mutuo = await MUTUO.deploy();

  await mutuo.deployed();

  console.log("NFT deployed to:", mutuo.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
