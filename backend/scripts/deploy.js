// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const Contract = await hre.ethers.getContractFactory("Nft");
  const contract = await Contract.deploy("ipfs://QmZvcBbTZXT2KPDNa8oWj2gaHaEmExvvrvKeeR1o7p7juL","0xf83ff10f25537121816d927e17f79370c3281c4dcb708e47142b3bc0dc41e916");

  await contract.deployed();

  console.log(
    `Contract deployed to ${contract.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
