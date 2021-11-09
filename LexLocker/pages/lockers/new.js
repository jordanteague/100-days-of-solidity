import React, { Component } from "react";
import {useState} from "react";
import { Form, Button, Input, Icon, Header, Loader, Label } from "semantic-ui-react";
import Layout from "../../components/Layout";
import instance from "../../instance";
import web3 from "../../web3";
import { Link } from "../../routes";
import PropTypes from 'prop-types';
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

const TerminationDate = () => {
  const [startDate, setStartDate] = useState(new Date());
  return (
    <DatePicker
      name="termination"
      dateFormat="MM/dd/yyyy hh:mm"
      selected={startDate}
      onChange={(date) => setStartDate(date)}
      showTimeSelect
    />
  );
};

class App extends Component {

  // variables set in state for testing purposes, will remove
  state = {
    loading: false,
    receiver: "0xEda65B971eD1976EFE6A7080B43f62daE2cA41Ae",
    resolver: "0x0B525473EC76Fe5d8B8bC0dF27f1e825A12494C5",
    token: "0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0",
    details: "test details",
    amount: 1000
  }

  checkNetwork(chainId) {
    if(chainId != 4) { //this version is on Rinkeby
      alert("Please connect to Rinkeby." );
    }
    if(!web3) {
      alert("Metamask required to use this dapp");
    }
  }

  deposit = async (event) => {
    const chainId = await web3.eth.getChainId();
    this.checkNetwork(chainId);
    this.setState({ loading: true });

    let object = event.target;
    var array = [];
    for(let i=0; i<object.length; i++) {
      array[object[i].name] = object[i].value;
      console.log(object[i].name+" - "+object[i].value);
    }

    // set variables; nft hard-coded as false for this version
    const { receiver, resolver, amount, token, termination, details } = array;
    const nft = false;

    // is resolver active?
    const isActive = await instance.methods.resolvers(resolver).call();

    if(isActive['active']==false) {
      alert("Please select an active resolver");
    } else {
        // convert dateTime to unix
        const unixDate = parseInt((new Date(termination).getTime() / 1000).toFixed(0));
        console.log(unixDate);

        // create "array" containing single uint for value; for simplicity's sake in this version
        const value = amount.split(",");
        console.log(value);

        try {
          const accounts = await web3.eth.getAccounts();
          const sender = accounts[0];
          let tx = await instance.methods.deposit(receiver, resolver, token, value, unixDate, nft, details)
            .send({ from: sender, value: parseInt(amount) });
          console.log(tx);
        } catch(error) {
          console.log(error);
        }
    }

    this.setState({ loading: false });
  }

  render() {

    return (
      <Layout>

        <Loader active={this.state.loading}></Loader>

        <Form onSubmit={this.deposit}>

          <Form.Field>
            <Label>Token Address
              <Label.Detail>What is the address of the token you are depositing?</Label.Detail>
            </Label>
            <Input
              name="token"
              value={this.state.token}
              onChange={(event) =>
                this.setState({ token: event.target.value })
              }
            />
          </Form.Field>

          <Form.Field>
            <Label>Deposit Amount
              <Label.Detail>How much are you depositing?</Label.Detail>
            </Label>
            <Input
              name="amount"
              value={this.state.amount}
              onChange={(event) =>
                this.setState({ amount: event.target.value })
              }
            />
          </Form.Field>

          <Form.Field>
            <Label>Receiver Address
              <Label.Detail>What is the address for the account that will receive payment?</Label.Detail>
            </Label>
            <Input
              name="receiver"
              value={this.state.receiver}
              onChange={(event) =>
                this.setState({ receiver: event.target.value })
              }
            />
          </Form.Field>

          <Form.Field>
            <Label>Resolver Address
              <Label.Detail>What is the address of the account that will resolve any disputes?</Label.Detail>
            </Label>
            <Input
              name="resolver"
              value={this.state.resolver}
              onChange={(event) =>
                this.setState({ resolver: event.target.value })
              }
            />
          </Form.Field>

          <Form.Field>
            <Label>Termination
              <Label.Detail>What is the cutoff date/time for depositor claiming back funds?</Label.Detail>
            </Label>
            <TerminationDate />
          </Form.Field>

          <Form.Field>
            <Label>Details
              <Label.Detail>Please briefly describe the reason for the deposit.</Label.Detail>
            </Label>
            <Input
              name="details"
              value={this.state.details}
              onChange={(event) =>
                this.setState({ details: event.target.value })
              }
            />
          </Form.Field>

          <Button
            icon
            labelPosition='left'
            primary><Icon name='send' />Deposit
          </Button>

        </Form>

      </Layout>
    );
  }
}

export default App;
