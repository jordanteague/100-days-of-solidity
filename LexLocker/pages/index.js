import React, { Component } from "react";
import Layout from '../components/Layout.js';
import instance from "../instance";
import web3 from "../web3";
import { Link } from "../routes";

class App extends Component {

  static async getInitialProps() {

    // THIS NEEDS TO BE A PUBLIC VARIABLE
    const lockerCount = parseInt(await instance.methods.lockerCount().call());
    console.log("lockerCount:"+lockerCount);

    return { lockerCount };

  }

  render() {

    return (
      <Layout>{this.props.lockerCount}</Layout>
    );
  }
}

export default App;
