import React, { Component } from "react";
import instance from "../instance";
import web3 from "../web3";
var Accounts = require('web3-eth-accounts');
const sigUtil = require('eth-sig-util');
const ethUtil = require('ethereumjs-util');

class App extends Component {
  state = { web3: null, accounts: null, contract: null };

  componentDidMount = async () => {
    try {
      const accounts = await web3.eth.getAccounts();
      this.setState({ web3, accounts, contract: instance }, this.runExample);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  runExample = async function(){

      const { accounts, contract } = this.state;

      const signer = accounts[0].toString();
      const index = 4; //hard coded for now

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

      var from = accounts[0];

      var params = [from, msgParams];
      var method = 'eth_signTypedData_v4';

      web3.currentProvider.sendAsync(
        {
          method,
          params,
          from,
        },
        function (err, result) {
          if (err) return console.dir(err);
          if (result.error) {
            alert(result.error.message);
          }
          if (result.error) return console.error('ERROR', result);
          console.log('TYPED SIGNED:' + JSON.stringify(result.result));
          const signature = result.result.substring(2);
          const recovered = sigUtil.recoverTypedSignature_v4({
            data: JSON.parse(msgParams),
            sig: result.result,
          });

          if (
            ethUtil.toChecksumAddress(recovered) === ethUtil.toChecksumAddress(from)
          ) {
            alert('Successfully recovered signer as ' + from);
            const r = "0x" + signature.substring(0, 64);
            const s = "0x" + signature.substring(64, 128);
            const v = parseInt(signature.substring(128, 130), 16);
            console.log("r:", r);
            console.log("s:", s);
            console.log("v:", v);
            const worked = contract.methods.signMeta(signer, index, v, r, s).send({ from: from });
            console.log(worked);
          } else {
            alert(
              'Failed to verify signer when comparing ' + result + ' to ' + from
            );
          }
        }
      );
  };


  render() {

    return (
      <div className="App">

      </div>
    );
  }
}

export default App;
