const registry = artifacts.require("Registry")

module.exports = async function (deployer) {
    await deployer.deploy(registry);
    const instance = await registry.deployed();
    console.log("deployed at", instance.address);
}