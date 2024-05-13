const { network, ethers } = require("hardhat")
const { deploymentChains, networkConfig, mockDeployment } = require("../helper.config.js")
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let vrfCoordinatorV2MockAddress, vrfSubscriptionId

    //本地（走mock数据）
    if (deploymentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        vrfCoordinatorV2MockAddress = vrfCoordinatorV2Mock.target
        const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
        const transactionReceipt = await transactionResponse.wait(1)
        console.log(transactionReceipt)
        // console.log(vrfCoordinatorV2Mock.SubscriptionCreated())
        // vrfSubscriptionId = transactionReceipt.events[0].args.subId

        await vrfCoordinatorV2Mock.fundSubscription(
            vrfSubscriptionId,
            mockDeployment.vrf_sub_fund_amount,
        )
    } else {
        //非本地

        vrfCoordinatorV2MockAddress = networkConfig[chainId]["vrf_Coordinator"]
        vrfSubscriptionId = networkConfig[chainId]["vrf_subscriptionId"]
    }

    const lottery_entranceFee = networkConfig[chainId]["lottery_entranceFee"]
    const vrf_keyHash = networkConfig[chainId]["vrf_keyHash"]
    const vrf__callbackGasLimit = networkConfig[chainId]["vrf__callbackGasLimit"]
    const automation_interval = mockDeployment._interval
    const arg = [
        vrfCoordinatorV2MockAddress,
        vrfSubscriptionId,
        vrf_keyHash,
        vrf__callbackGasLimit,
        lottery_entranceFee,
        automation_interval,
    ]
    const lottery = await deploy("Lottery", {
        from: deployer,
        arg,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    //verify

    log("--------------------------------")
    log("Lottery deployed at:", lottery.target)
}

module.exports.tags = ["all", "lottery"]
