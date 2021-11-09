import React, { Component } from "react";
import { Table, Button } from "semantic-ui-react";
import Layout from '../components/Layout.js';
import instance from "../instance";
import web3 from "../web3";
import { Link } from "../routes";

class App extends Component {

  static async getInitialProps() {

    const lockerCount = parseInt(await instance.methods.lockerCount().call());

    const lockers = await Promise.all(
      Array(parseInt(lockerCount))
        .fill()
        .map((element, index) => {
          return instance.methods.lockers(index).call();
        })
    );

    return { lockerCount, lockers };

  }

  renderRows() {
    const { Row, Cell } = Table;

    return this.props.lockers.map((locker, index) => {

      return (
        <Row>
          <Cell>{locker["depositor"]}</Cell>
          <Cell>{locker["receiver"]}</Cell>
          <Cell>{locker["resolver"]}</Cell>
          <Cell>{locker["token"]}</Cell>
          <Cell>{locker["sum"]}</Cell>
          <Cell>{locker["locked"].toString()}</Cell>
        </Row>
      );
    });
  }

  render() {

    const { Header, Row, HeaderCell, Body } = Table;

    return (
        <Layout>
        <Link route="/lockers/new"><a><Button>Add New</Button></a></Link>
        <h3>Lockers</h3>
        <Table style={{ overflow: 'auto', display: 'inline-block', maxHeight: 'inherit', }}>
          <Header>
            <Row>
              <HeaderCell>Depositor</HeaderCell>
              <HeaderCell>Receiver</HeaderCell>
              <HeaderCell>Resolver</HeaderCell>
              <HeaderCell>Token</HeaderCell>
              <HeaderCell>Value</HeaderCell>
              <HeaderCell>Locked</HeaderCell>
            </Row>
          </Header>
          <Body>{this.renderRows()}</Body>
        </Table>

        <div>Found {this.props.lockerCount} lockers.</div>
        </Layout>
    );
  }
}

export default App;
