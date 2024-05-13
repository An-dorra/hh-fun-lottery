const { network } = require("hardhat")

const { deploymentChains, mockDeployment } = require("../helper.config.js")
const { _baseFee, _gasPriceLink } = mockDeployment

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    if (deploymentChains.includes(network.name)) {
        // deploy a mock vrfCoordinator

        log("Deploying a mock VRFCoordinator and waiting for confirmations...")
        const args = [_baseFee, _gasPriceLink]
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args,
        })
        log("----------------------------------------------------")
        log("Mocks Deployed")
    }
}

module.exports.tags = ["all", "mocks"]
