import web3 from "./web3";
import LexNFTIncrementalMintableOwnable from "./artifacts/contracts/LexNFTIncrementalMintableOwnable.sol/LexNFTIncrementalMintableOwnable.json";

const instance = new web3.eth.Contract(
  LexNFTIncrementalMintableOwnable.abi,
  "0x88F5FDc11dF0fA35ADAFf8b38db03eA49F4d99c5" //need address
);

export default instance;
