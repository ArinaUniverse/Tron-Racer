const port = process.env.HOST_PORT || 9090

const fs = require('fs');
const p = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
    dappchain: {
      // Don't put your private key here:
      privateKey: p,
      /*
Create a .env file (it must be gitignored) containing something like

  export PRIVATE_KEY_DAPPCHAIN=4E7FECCB71207B867C495B51A9758B104B1D4422088A87F4978BE64636656243

Then, run the migration with:

  source .env && npx sun-photon migrate --network dappchain

*/
      userFeePercentage: 100,
      feeLimit: 1e8,
      mainFullHost: 'https://api.trongrid.io',
      sideFullHost: 'https://sun.tronex.io',
      mainGateway: 'TWaPZru6PR5VjgT4sJrrZ481Zgp3iJ8Rfo',
      sideGateway: 'TGKotco6YoULzbYisTBuP6DWXDjEgJSpYz',
      chainId: '41E209E4DE650F0150788E8EC5CAFA240A23EB8EB7',
      network_id: '1'
    },
    testnet: {
      privateKey: p,
      userFeePercentage: 50,
      feeLimit: 1e8,
      mainFullHost: 'https://testhttpapi.tronex.io',
      sideFullHost: 'https://suntest.tronex.io',
      mainGateway: 'TFLtPoEtVJBMcj6kZPrQrwEdM3W3shxsBU',
      sideGateway: 'TRDepx5KoQ8oNbFVZ5sogwUxtdYmATDRgX',
      chainId: '413AF23F37DA0D48234FDD43D89931E98E1144481B',
      network_id: '2'
    },
    development: {
      // For trontools/quickstart docker image
      privateKey: p,
      userFeePercentage: 0,
      feeLimit: 1e8,
      mainFullHost: 'https://testhttpapi.tronex.io',
      sideFullHost: 'http://127.0.0.1:' + port,
      mainGateway: 'TFLtPoEtVJBMcj6kZPrQrwEdM3W3shxsBU',
      sideGateway: 'TRDepx5KoQ8oNbFVZ5sogwUxtdYmATDRgX',
      chainId: '',
      network_id: '9'
    },
    compilers: {
      solc: {
        version: '0.5.4'
      }
    }
  }
}
