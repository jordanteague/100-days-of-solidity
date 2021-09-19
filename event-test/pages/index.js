import React, { Component } from "react";
import { Card } from "semantic-ui-react";
import sendMoney from "../ethereum/sendMoney";
//import Layout from "../components/Layout";
//import { Link } from "../routes";

class SendMoney extends Component {

  static async getInitialProps() {

    const pastEvents = await sendMoney.getPastEvents('moneySent', {fromBlock: 0, toBlock: 'latest'});
    const sender = await sendMoney.methods.sender().call();
    const message = await sendMoney.methods.message().call();

    console.log(pastEvents);
    console.log(sender);
    console.log(message);

    return { sender, message, pastEvents };

  }

  renderEvents() {
    const items = this.props.pastEvents.map((pastEvents) => {
      return {
        header: "blockHash: " + pastEvents.blockHash,
        description: "blockNumber: " + pastEvents.blockNumber,
        fluid: true,
      };
    });
    return <Card.Group items={items} />;
  }
  render() {
    return (
        <div>
          <h3>Past Events</h3>

          {this.renderEvents()}
        </div>
    );
  }
}

export default SendMoney;
