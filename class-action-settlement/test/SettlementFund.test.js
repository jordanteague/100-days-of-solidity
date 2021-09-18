const assert = require("assert");
const ganache = require("ganache-cli");
const Web3 = require("web3");
const web3 = new Web3(ganache.provider());
const compiledContract = require("../build/SettlementFund.json");

beforeEach(async () => {

  accounts = await web3.eth.getAccounts();

  classMembers = JSON.parse('["0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c"]');

  deployedContract = await new web3.eth.Contract(compiledContract.abi)
    .deploy({
      data: compiledContract.evm.bytecode.object,
      arguments: [classMembers, "0x617F2E2fD72FD9D5503197092aC168c91465E7f2",1000000,100000]
    })
    .send({ from: accounts[0], gas: "1000000", gasPrice: '5000000000' });

    await deployedContract.methods.setContractAddress(deployedContract.options.address).call();

});

describe("Tests", () => {
  it("deploys a contract", () => {
    assert.ok(deployedContract.options.address);
  });

});
