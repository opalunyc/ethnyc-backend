// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

//returns ether balance of a given address
async function getBalance(address) {
  const balanceBigInt = await hre.waffle.provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}


//logs the ether balances for a list of addresses. 
async function printBalances(addresses) {
  let idx = 0;
  for(const address of addresses) {
    console.log(`Address ${idx} balance: `, await getBalance(address));
    idx++;
  }
}


// //logs memos stored on-chain
// async function printMemos(memos) {
//   for (const memo of memos) {
//     const timestamp = memo.timestamp;
//     const tipper = memo.name;
//     const tipperAddress = memo.from;
//     const message = memo.message;
//     console.log(`At ${timestamp}, ${tipper}, (${tipperAddress}) said: "${message}" `)
//   }
// }




async function main() {
  // Get example accounts.

  const [owner, recipient] = await hre.ethers.getSigners();

  //Get contract to deploy & deploy

  const Lossy = await hre.ethers.getContractFactory("Lossy");
  const lossy = await Lossy.deploy(2,10,recipient.address);
  await lossy.deployed();

  console.log("Lossy deployed to ", lossy.address)


  //Check balances before time complete

  const addresses = [owner.address, recipient.address, lossy.address];
  console.log("===START===")


  await printBalances(addresses);

  console.log("==rate==");
  const rate = await lossy.rate();
  console.log("Rate: ",rate);


  console.log("==frequency==");
  const frequency = await lossy.frequency();
  console.log("Freq",frequency);


  const lastCheckIn = await lossy.lastCheckIn();
  console.log("Last checked in:", lastCheckIn)

  const hasCheckedIn = await lossy.





  // console.log("====");
  // const memos = await buyMeACoffee.getMemos();
  // printMemos(memos);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
