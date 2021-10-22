import React, { Component } from "react";
import { Form, Button, Input, Grid, Icon, Header } from "semantic-ui-react";
import Layout from "../components/Layout";
import instance from "../instance";
import web3 from "../web3";

class App extends Component {

  state = {
    signer: "",
    r: "",
    s: "",
    v: "",
    signature: "",
    index: "",
    accounts: "",
    chainId: null,
    network: null,
    loading1: false,
    loading2: false
  }

  componentDidMount = async () => {
    const accounts = await web3.eth.getAccounts();
    const signer = accounts[0];
    const chainId = await web3.eth.getChainId();
    const network = await web3.eth.net.getNetworkType();
    this.setState({ accounts, signer, chainId, network }); // this info really needs to reset if network/account changed in metamask
  }

  getSig = async (event) => {

    event.preventDefault();
    this.setState({ loading1: true });

    const { accounts, signer, chainId, network, index } = this.state;

    if(chainId != 4) { //this version is on Rinkeby
      alert("Please connect to Rinkeby." );
    }
    if(!web3) {
      alert("Metamask required to use this dapp");
    }

    const msgParams = JSON.stringify({
      domain: {
        chainId: 4, //Rinkeby
        name: 'SignableRegistry',
        verifyingContract: '0xb643C238328CFfAdeb7A73Ca8fc19EcfAF1c1415', //SignableRegistry on Rinkeby
        version: '1',
      },

      message: {
        signer: signer,
        index: index //index of content to be signed
      },
      // Refers to the keys of the *types* object below.
      primaryType: 'SignMeta',
      types: {
        // TODO: Clarify if EIP712Domain refers to the domain the contract is hosted on
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        // Not an EIP712Domain definition
        SignMeta: [
          { name: 'signer', type: 'address' },
          { name: 'index', type: 'uint256' },
        ],
      },
    });

    var params = [signer, msgParams];
    var method = 'eth_signTypedData_v4';

    web3.currentProvider.sendAsync(
      {
        method,
        params,
        signer,
      },
      (err, result) => {
        if (err) {
        } else if (result && result.error) {

        } else {
            const signature = result.result.substring(2);
            const r = "0x" + signature.substring(0, 64);
            const s = "0x" + signature.substring(64, 128);
            const v = parseInt(signature.substring(128, 130), 16);

            this.setState({ r, s, v, signature });
            console.log("signer:"+signer);
            console.log("content:"+index);
            console.log("r:"+r);
            console.log("s:"+s);
            console.log("v:"+v);
            this.setState({ loading1: false });
        }
      }
    );

  };

  registerSig = async (event) => {
    event.preventDefault();
    this.setState({ loading2: true });
    if(this.state.chainId != 4) { //this version is on Rinkeby
      alert("Please connect to Rinkeby." );
    }
    if(!web3) {
      alert("Metamask required to use this dapp");
    }

    const accounts = await web3.eth.getAccounts();
    const sender = accounts[0];
    const { signer, index, v, r, s } = this.state;

    let tx = await instance.methods.signMeta(
      signer,
      index,
      v,
      r,
      s)
    .send({ from: sender });
    this.setState({ loading2: false });
    console.log(tx);
  }

  checkSig = async (event) => {
    const accounts = await web3.eth.getAccounts();
    const { signer, index } = this.state;
    const isSigned = await instance.methods.checkSignature(
      signer,
      index
    ).call();
    alert(isSigned);
  }

  render() {

    return (
      <Layout>
      <Grid columns={3} divided>
      <Grid.Column width={5}>
      <Header
        as='h3'
        content='1. Generate Signature'
        subheader='Sign content with your ETH account.'
      />
      <Form onSubmit={this.getSig}>
        <Form.Field>
          <label>signer (autodetected)</label>
          <Input
            icon="key" iconPosition="left"
            value={this.state.signer}
            disabled
          />
        </Form.Field>
        <Form.Field>
          <label>content index (uint256)</label>
          <Input
            icon="calculator" iconPosition="left"
            value={this.state.index}
            onChange={(event) =>
              this.setState({ index: event.target.value })
            }
          />
        </Form.Field>
          <p><Icon name='fork' />chain: {this.state.chainId} ({this.state.network})</p>
        <Button loading={this.state.loading1} icon labelPosition='left' primary><Icon name='pencil' />Sign</Button>
      </Form>
      </Grid.Column>

      <Grid.Column width={5}>
      <Header
        as='h3'
        content='2. Register Signature'
        subheader='Register your signature on the blockchain.'
      />
      <Form onSubmit={this.registerSig}>
        <Form.Field>
          <label>signer</label>
          <Input value={this.state.signer} disabled />
        </Form.Field>
        <Form.Field>
          <label>content index (uint)</label>
          <Input value={this.state.index} disabled />
        </Form.Field>
        <Form.Field>
          <label>r</label>
          <Input value={this.state.r} disabled />
        </Form.Field>
        <Form.Field>
          <label>s</label>
          <Input value={this.state.s} disabled />
        </Form.Field>
        <Form.Field>
          <label>v</label>
          <Input value={this.state.v} disabled />
        </Form.Field>
        <Button loading={this.state.loading2} icon labelPosition='left' primary><Icon name='lock' />Register</Button>
      </Form>
      </Grid.Column>

      <Grid.Column width={5}>
      <Header
        as='h3'
        content='3. Confirm Signature'
        subheader='Check blockchain to confirm signature.'
      />
      <Form onSubmit={this.checkSig}>
        <Form.Field>
          <label>content index (uint)</label>
          <Input
            value={this.state.index}
            onChange={(event) =>
              this.setState({ index: event.target.value })
            }
          />
        </Form.Field>
        <Form.Field>
          <label>signer</label>
          <Input
            value={this.state.signer}
            onChange={(event) =>
              this.setState({ signer: event.target.value })
            }
          />
        </Form.Field>
        <Button icon labelPosition='left' primary><Icon name='check' />Check</Button>
      </Form>
      </Grid.Column>
      </Grid>
      </Layout>
    );
  }
}

export default App;
