import React, { Component } from "react";
import { Form, Button, Icon, Label, Segment, Loader, Message } from "semantic-ui-react";
import Layout from "../components/Layout";
import web3 from "../web3";
import instance from "../instance";
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

class App extends Component {

  state = {
      accounts: null,
      merkleTree: null,
      root: null,
      loading: false,
      message: null,
      messageVisible: false
  }

  componentDidMount = async () => {
      const accounts = await web3.eth.getAccounts();
      this.setState({ accounts });
      this.createMerkleTree();
  }

  checkNetwork = async () => {
    const chainId = await web3.eth.getChainId();
    if(chainId != 4) { //this version is on Rinkeby
      alert("Please connect to Rinkeby." );
    }
    if(!web3) {
      alert("Metamask required to use this dapp");
    }
  }

  createMerkleTree = async (event) => {
    this.checkNetwork();
    //admin manually provide addresses and generate Merkle tree
    //this runs every time page refreshes, but you could generate tree/root only once
    //ror instance, could write the tree to a text file
    const list = [
        '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
        '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
        '0x90F79bf6EB2c4f870365E785982E1f101E93b906',
        '0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65',
        '0x0B525473EC76Fe5d8B8bC0dF27f1e825A12494C5',
        '0xE3bbFD7dbd338a2C1c4F28F8e06aC00589118c4B'
    ];

    const merkleTree = new MerkleTree(list, keccak256, { hashLeaves: true, sortPairs: true });

    const root = merkleTree.getHexRoot();

    this.setState({ merkleTree, root });

  }

  claimWhiteList = async (event) => {
    event.preventDefault();
    this.setState({ loading: true, messageVisible: false });
    this.checkNetwork();
    const { merkleTree } = this.state;
    const claimer = this.state.accounts[0];
    const proof = merkleTree.getHexProof(keccak256(claimer));
    console.log(proof); //user will never actually need to see this
    let tx = await instance.methods.claimWhiteList(proof).send({ from: claimer });
    console.log(tx);
    this.setState({ loading: false, messageVisible: true, message: "Successfully claimed whitelist status" });
  }

  whitelisted = async (event) => {
    event.preventDefault();
    this.checkNetwork();
    this.setState({ loading: true, messageVisible: false });
    const claimer = this.state.accounts[0];
    let isWhiteListed = await instance.methods.whitelisted(claimer).call();
    let message;
    if(isWhiteListed==true) {
      message = "You are on the whitelist."
    } else {
      message = "You are not on the whitelist. If you are eligible, please claim your whitelist spot."
    }
    this.setState({ message, loading: false, messageVisible: true });
  }

  renderMessage() {
    if (this.state.messageVisible==true) {
      return (
        <Message>
          {this.state.message}
        </Message>
      )
    } else {
      console.log("nope")
    }
  }

  render() {

    return (
      <Layout>
        {this.renderMessage()}
        <Loader active={this.state.loading}></Loader>
          <Segment textAlign='center'>
          <Form onSubmit={this.claimWhiteList}>
            <Button primary><Icon name='add' />Claim Whitelist Status</Button>
          </Form>
          </Segment>
          <Segment textAlign='center'>
          <Form onSubmit={this.whitelisted}>
            <Button primary><Icon name='check' />Confirm Whitelisted</Button>
          </Form>
          </Segment>
      </Layout>
    );
  }
}

export default App;
