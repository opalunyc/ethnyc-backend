const hre = require("hardhat");


async function main() {
  const Lossy = await hre.ethers.getContractFactory("Lossy");
  const lossy = await Lossy.deploy(1,'0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D');
  await lossy.deployed();
  console.log("Lossy deployed to ", lossy.address);

}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
