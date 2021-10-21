import React from "react";
import { Header } from "semantic-ui-react";

const MyHeader = () => {
  return (
    <React.Fragment>
    <Header as='h1' textAlign='center'>cryptosig</Header>
    <Header as='h3' textAlign='center'>sign text with your ETH address</Header>
    </React.Fragment>
  );
};

export default MyHeader;
