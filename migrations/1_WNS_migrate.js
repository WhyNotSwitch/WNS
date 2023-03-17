const WNS = artifacts.require("WhyNotSwitch")

module.exports = async function (deployer) {
    await deployer.deploy(WNS);
    const instance = await WNS.deployed();
    console.log("deployed at", instance.address);
}