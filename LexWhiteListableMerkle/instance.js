import web3 from "./web3";
import LexNFTIncrementalMintableOwnable from "./artifacts/contracts/LexNFTIncrementalMintableOwnable.sol/LexNFTIncrementalMintableOwnable.json";

const instance = new web3.eth.Contract(
  LexNFTIncrementalMintableOwnable.abi,
  "0xC0Bffc0126924B54C9370D0e3B2Ab9af096c872E" //need address
);

export default instance;
