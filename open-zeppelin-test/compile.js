const path = require('path');
const fs = require('fs-extra');
const solc = require('solc');

const builPath = path.resolve(__dirname, 'build');
const contractsFolderPath = path.resolve(__dirname, 'contracts');

const createBuildFolder = () => {
	fs.emptyDirSync(builPath);
}

const buildSources = () => {

	const sources = {};
	const contractsFiles = fs.readdirSync(contractsFolderPath);

	contractsFiles.forEach(file => {
		const contractFullPath = path.resolve(contractsFolderPath, file);
		sources[file] = {
			content: fs.readFileSync(contractFullPath, 'utf8')
		};
	});

	return sources;
}

const input = {
	language: 'Solidity',
	sources: buildSources(),
	settings: {
		outputSelection: {
			'*': {
				'*': [ 'abi', 'evm.bytecode' ]
			}
		}
	}
}

const compileContracts = () => {
	const compiledContracts = JSON.parse(solc.compile(JSON.stringify(input))).contracts;

	for (let contract in compiledContracts) {
		for(let contractName in compiledContracts[contract]) {
			fs.outputJsonSync(
				path.resolve(builPath, `${contractName}.json`),
				compiledContracts[contract][contractName],
				{
					spaces: 2
				}
			)
		}
	}
}

(function run () {
	createBuildFolder();
	compileContracts();
})();
