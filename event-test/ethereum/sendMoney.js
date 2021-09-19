import web3 from "./web3";
import SendMoney from "./build/SendMoney.json";

const instance = new web3.eth.Contract(
  SendMoney.abi,
  "0x66FBF08bcCab730CBC632cE6EeAF7848bE73eF84"
);

export default instance;
