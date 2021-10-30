import web3 from "./web3";
import LexLocker from "./build/contracts/LexLocker.json";


const instance = new web3.eth.Contract(
  LexLocker.abi,
  "0x91d9Cf6aC37F82F2257F839274b49e7322B5220d"
);

export default instance;
