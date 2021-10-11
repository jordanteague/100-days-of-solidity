const { expect } = require("chai");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs-extra');

describe("LexNFT", function () {
  let owner, addr1, addr2, addr3, addr4, addr5, addr6;
  let LexNFT, lexNFT, list, merkleTree, root;

  beforeEach(async function() {
      [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();

      LexNFT = await ethers.getContractFactory("LexNFT");

      lexNFT = await LexNFT.deploy("LexCoin", "LEX", 1, "ipfs://", "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199", true);

      await lexNFT.deployed();

      list = [
          '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
          '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
          '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
          '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
          '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65'
      ];

      merkleTree = new MerkleTree(list, keccak256, { hashLeaves: true, sortPairs: true });

      root = merkleTree.getHexRoot();

      await lexNFT.setMerkleRoot(root);

  });

  it("Should register addr2 as claimant", async function () {

    const proof = merkleTree.getHexProof(keccak256(addr2.address));

    await lexNFT.connect(addr2).claimWhiteList(proof);

    expect(await lexNFT.whitelisted(addr2.address)).to.be.true;

  });

  it("Should not have a merkle proof for addr5", async function () {

    expect (merkleTree.getHexProof(keccak256(addr5.address))).to.be.empty;

  });

  it("Should reject an invalid/mismatched merkle proof", async function () {

    //get proof for addr2, but try with addr4
    const proof = merkleTree.getHexProof(keccak256(addr2.address));

    async function assertFailure (promise) {
    try {
        await expectRevert.unspecified(lexNFT.connect(addr4).claimWhiteList(proof));
      } catch (error) {
        return error;
      }
      expect.fail();
    }

  });

});
