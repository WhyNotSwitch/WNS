const Marketplace = artifacts.require("Marketplace")

module.exports = async function (deployer) {
    await deployer.deploy(Marketplace);
    const marketplace = await Marketplace.deployed();
    console.log("deployed at", marketplace.address);
}