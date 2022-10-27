// migrations/NN_deploy_upgradeable_box.js
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const Marketplace = artifacts.require("Marketplace")

module.exports = async function (deployer) {
  const instance = await deployProxy(Marketplace, [42], { deployer });
  console.log('Deployed at', instance.address);
};


// // migrations/MM_upgrade_box_contract.js
// const { upgradeProxy } = require('@openzeppelin/truffle-upgrades');

// const Box = artifacts.require('Box');
// const BoxV2 = artifacts.require('BoxV2');

// module.exports = async function (deployer) {
//   const existing = await Box.deployed();
//   const instance = await upgradeProxy(existing.address, BoxV2, { deployer });
//   console.log("Upgraded", instance.address);
// };