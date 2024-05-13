const { ethers } = require("hardhat")
const networkConfig = {
    11155111: {
        name: "sepolia",
        vrf_Coordinator: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
        vrf_keyHash: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
        vrf__callbackGasLimit: 2500000,
        lottery_entranceFee: ethers.parseEther("0.01"),
        vrf_subscriptionId:
            "9882558435133733082537369141674276635685575010425139975490719042339385234335",
    },
    31337: {
        name: "hardhat",
        lottery_entranceFee: ethers.parseEther("0.01"),
        vrf__callbackGasLimit: 2500000,
        vrf_keyHash: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c",
    },
}

const deploymentChains = ["hardhat", "localhost"]

const mockDeployment = {
    _baseFee: ethers.parseEther("0.25"),
    vrf_sub_fund_amount: ethers.parseEther("30"),
    _gasPriceLink: 1e9,
    _interval: 5,
}

module.exports = {
    networkConfig,
    deploymentChains,
    mockDeployment,
}
