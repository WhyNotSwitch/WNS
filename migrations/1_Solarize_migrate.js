const Solarize = artifacts.require("Solarize")

module.exports = async function (deployer) {
    await deployer.deploy(Solarize);
    const solarize = await Solarize.deployed();
    console.log("deployed at", solarize.address);
}