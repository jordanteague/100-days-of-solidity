import React, { Component } from "react";
import { Container, Form, TextArea, Input, Label, Button, Icon, Divider, Message } from "semantic-ui-react";
import Layout from "../components/Layout";
import web3 from "../web3";

class App extends Component {

  state = {
    signer: "",
    content: "",
    hash: "",
    signature: "",
    sigVisible: false,
    recovered: "",
    recoveredVisible: false,
    chainId: null,
    network: null
  }

  componentDidMount = async () => {
    const accounts = await web3.eth.getAccounts();
    const signer = accounts[0];
    const chainId = await web3.eth.getChainId();
    const network = await web3.eth.net.getNetworkType();
    this.setState({ signer, chainId, network }); // this info really needs to reset if network/account changed in metamask
  }

  generateSignature = async (event) => {
    event.preventDefault();
    const accounts = await web3.eth.getAccounts();
    const signer = accounts[0];
    const content = event.target[0].value;
    const hash = web3.eth.accounts.hashMessage(content);
    const signature = await web3.eth.personal.sign(hash, signer);
    this.setState({ signer, content, hash, signature, sigVisible: true });
  };

  validateSignature = async (event) => {
    event.preventDefault();
    const hash = event.target[1].value;
    const signature = event.target[0].value;
    const recovered = web3.eth.accounts.recover(hash, signature);
    this.setState({ recovered, recoveredVisible: true });
  }

  render() {
    return(
      <Layout>
      <Container>
        <Form onSubmit={this.generateSignature}>
          <Form.Field>
            <Label attached='top'><Icon name='file text' />Content to sign</Label>
            <TextArea />
          </Form.Field>
          <p><Icon name='key' />account: {this.state.signer}</p>
          <p><Icon name='fork' />chain: {this.state.chainId} ({this.state.network})</p>
          <Button primary><Icon name='pencil' />Sign</Button>
        </Form>

        {this.state.sigVisible ?
          <React.Fragment>
            <Divider />
            <Form onSubmit={this.validateSignature}>
            <Form.Field>
              <Input label="signature" labelPosition="left" type='text' value={this.state.signature} disabled />
            </Form.Field>
            <Form.Field>
              <Input label="content hash" labelPosition="left" type='text' value={this.state.hash} disabled />
            </Form.Field>
            <Button primary><Icon name='check circle' />Validate</Button>
            </Form>
          </React.Fragment>
           : null}
           {this.state.recoveredVisible ?
             <React.Fragment>
             <Divider />
             <Message positive>
               <Message.Header>Successfully Recovered Signer</Message.Header>
               <p>{this.state.recovered}</p>
             </Message>
             </React.Fragment>
              : null}
        </Container>
      </Layout>
    );
  }

}
export default App;
