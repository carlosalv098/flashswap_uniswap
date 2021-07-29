const hre = require("hardhat");

async function main() {

    const Flashswap_Uniswap = await hre.ethers.getContractFactory("Flashswap_uniswap");
    const flashswap_uniswap = await Flashswap_Uniswap.deploy();

    await flashswap_uniswap.deployed();

    console.log("flashswap_uniswap deployed to:", flashswap_uniswap.address);

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });