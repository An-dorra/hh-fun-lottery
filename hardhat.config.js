/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const { PRIVATE_KEY, RPC_URL, VERIFY_APP_KEYS } = process.env

module.exports = {
    solidity: "0.8.7",
    defaultNetwork: "hardhat",
    namedAccounts: {
        deployer: {
            default: 0,
        },
        players: {
            default: 1,
        },
    },
    networks: {
        sepolia: {
            url: RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 11155111,
            blockConfirmations: 6,
        },
        localhost: {
            url: "http://127.0.0.1:8545",
            chainId: 31337,
        },
    },
    etherscan: {
        apiKey: VERIFY_APP_KEYS,
    },
    gasReporter: {
        enabled: true,
        outputFile: "gas-reporter.txt",
        noColors: true,
        // coinmarketcap: COINMARKETCAP_API_KEY,
        currency: "USD",
    },
}
