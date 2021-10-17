import web3 from "./web3";
import SignableRegistry from "./artifacts/contracts/SignableRegistry.sol/SignableRegistry.json";

const instance = new web3.eth.Contract(
  SignableRegistry.abi,
  "0xb643C238328CFfAdeb7A73Ca8fc19EcfAF1c1415" //need address
);

export default instance;
