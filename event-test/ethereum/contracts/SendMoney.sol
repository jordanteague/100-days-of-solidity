//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendMoney{

    event moneySent(address _from, address _to, uint _amount);

    address public sender;

    string public message;

    constructor() {
        sender = msg.sender;
        message = "Hi";
    }

    function sendMessage(string memory _message) public {
      message = _message;
    }

    function sendMoney(address payable _recipient) public payable {

        require(msg.sender == sender);

        require(msg.sender.balance >= msg.value);

       _recipient.transfer(msg.value);

       emit moneySent(msg.sender, _recipient, msg.value);

    }

}
