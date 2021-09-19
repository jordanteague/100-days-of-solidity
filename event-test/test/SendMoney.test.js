const assert = require("assert");
const ganache = require("ganache-cli");
const Web3 = require("web3");
const web3 = new Web3(ganache.provider());
const compiledContract = require("../build/SendMoney.json");

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  deployedContract = await new web3.eth.Contract(compiledContract.abi)
    .deploy({ data: compiledContract.evm.bytecode.object })
    .send({ from: accounts[0], gas: "1000000", gasPrice: '5000000000' });
});

describe("Tests", () => {
  it("deploys a contract", () => {
    assert.ok(deployedContract.options.address);
  });

  it("deploys a contract", () => {
    assert.ok(deployedContract.options.address);
  });

});
