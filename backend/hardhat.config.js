require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",

  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  
  networks: {
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/UaaYF43sj3JMJovB77fp8Zke3Dg0LUko",
      account: [`0x${process.env.PRIVATE_KEY}`],
      chainId: 5,
    },
    
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      account: [`${process.env.PRIVATE_KEY}`],
      chainId: 80001,
    },
  },
  
  // ganache: {
  //   url: 'http://localhost:8545',
  // },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },

  etherscan: {
    apiKey: "57M6RGRNETYA7RZ53WQHSBMMWC3JF2X2K6" 
  },
  polyscan: {
    apiKey: "57M6RGRNETYA7RZ53WQHSBMMWC3JF2X2K6"
  }
}