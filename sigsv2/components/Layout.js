import React from "react";
import { Container } from "semantic-ui-react";
import Head from "next/head";
import MyHeader from "./Header";

const Layout = (props) => {
  return (
    <div>
      <Container style={{ marginTop: "50px" }}>
        <Head>
          <link
            rel="stylesheet"
            href="//cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.12/semantic.min.css"
          ></link>
        </Head>
        <MyHeader />
        {props.children}
      </Container>
    </div>
  );
};
export default Layout;
