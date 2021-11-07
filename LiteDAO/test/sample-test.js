const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Proposals", function () {

  beforeEach(async function() {

      [owner] = await ethers.getSigners();
      Proposals = await ethers.getContractFactory("Proposals");
      proposals = await Proposals.deploy(3);
      await proposals.deployVoteCoin("VoteCoin", "VOTE", 8, 1000000);
      voteCoin = await proposals.voteCoin();
  });

  it("Proposals should have an address", async function () {
    console.log(proposals.address);
    expect(proposals.address).to.be.ok;
  });
  it("Votecoin should have an address", async function () {
    console.log(voteCoin);
    expect(voteCoin).to.be.ok;
  });

  it("Should be able to call voteCoin", async function () {
    let abi = [ "function getPriorVotes(address, uint256)" ];
    let iface = new ethers.utils.Interface(abi);
    let calldata = iface.encodeFunctionData("getPriorVotes", ["0xE3bbFD7dbd338a2C1c4F28F8e06aC00589118c4B", 1635713574]);
    abiCoder = ethers.utils.defaultAbiCoder;
    console.log(calldata);
    var response = await proposals.call(voteCoin, calldata);
    console.log(response);
    //var result = ethers.utils.verifyString(response.data, response.v, response.r, response.s);
    var result = abiCoder.decode(["uint256"], ethers.utils.hexDataSlice(response.data, 4));
    console.log(result);
    //expect(result).to.be.ok;
  });

});
