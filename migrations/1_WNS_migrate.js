const WNS = artifacts.require("WNS")

module.exports = async function (deployer) {
    await deployer.deploy(WNS);
    const wns = await WNS.deployed();
    console.log("deployed at", wns.address);
}