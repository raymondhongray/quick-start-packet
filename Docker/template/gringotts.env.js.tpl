var argv = require('minimist')(process.argv.slice(2), { string: ['serverAddress', 'contractAddress'] });

let env = {
  //web3Host: '<WEB3_HOST>',
  //web3Port: '<WEB3_PORT>',
  web3Host: 'gethpoa',
  web3Port: '8545',
  web3Url: 'ws://gethpoa:8546',
  serverAddress: '<POA_SIGNER_ADDRESS>',
  contractAddress: '<BOOSTER_ADDRESS>',
  //boosterPort: '<IFC_GRINGO_PORT>',
  boosterPort: 3000,
  production: {
    //username: '<POSTGRES_USER>',
    //password: '<POSTGRES_PASSWORD>',
    //database: '<POSTGRES_DB>',
    //host: '<POSTGRES_HOST>',
    username: 'harry',
    password: 'potter',
    database: 'gringot',
    host: 'postgres',
    dialect: 'postgres',
    logging: false
  }
};

if (!argv.hasOwnProperty('migrations-path')) {
  Object.keys(env).forEach((key) => {
    if (key != 'production') {
      let value = env[key];
      if (!value) {
        throw new Error('Missing config: ' + key);
      }
    }
  });
}

module.exports = env;