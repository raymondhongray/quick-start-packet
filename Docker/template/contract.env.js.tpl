let env = {
  devnet: {
    web3Url: 'http://gethpoa:8545',
    privateKey: '<POA_SIGNER_PRI_KEY>',
  },
  testnet: {
    web3Url: 'https://rinkeby.infura.io/YOUR_TESTNET_TOKEN',
    privateKey: '<POA_SIGNER_PRI_KEY>',
  },
  mainnet: {
    web3Url: 'https://mainnet.infura.io/YOUR_MAINNET_TOKEN',
    privateKey: '<POA_SIGNER_PRI_KEY>',
  }
};

module.exports = env;