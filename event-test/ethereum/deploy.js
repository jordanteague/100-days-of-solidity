const HDWalletProvider = require('truffle-hdwallet-provider');
const Web3 = require('web3');
const compiledContract = require('./build/SendMoney.json');

const provider = new HDWalletProvider(
	'kind unusual raven fiber code settle riot merit bright drive blast stadium',
	'https://rinkeby.infura.io/v3/010c8fd471f24158872912bba4187523'
);

const web3 = new Web3(provider);

(async () => {
	const accounts = await web3.eth.getAccounts();

	console.log(`Attempting to deploy from account: ${accounts[0]}`);

	const deployedContract = await new web3.eth.Contract(compiledContract.abi)
		.deploy({
			data: '0x' + compiledContract.evm.bytecode.object,
			arguments: []
		})
		.send({
			from: accounts[0],
			gas: '2000000',
			gasPrice: '5000000000'
		});

	console.log(
		`Contract deployed at address: ${deployedContract.options.address}`
	);

	provider.engine.stop();
})();
