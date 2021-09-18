// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Newbie attempt at a class action settlement fund contract.  Pretty basic.

contract SettlementFund {

    address private administrator; //settlement adminstrator

    address public classCounsel; //because class counsel gets attorney fees

    address[] public claimants; //array of addresses of those who submit claims

    mapping(address => bool) public classMembers; //addresses of those who are eligible to submit claims

    address contractAddress; //is there a global function for this in Solidity?

    uint fundAmount; //amount defendant is required to pay

    uint attyFees; //lawyers gotta eat

    bool fundIsClosed = false; //once funds are disbursed, fund should be closed

    constructor(
            address[] memory _classMembers,
            address _classCounsel,
            uint256 _fundAmount,
            uint _attyFees
    ) {
        require(_fundAmount > _attyFees, "The lawyers don't get all the money.");

        for(uint i = 0; i < _classMembers.length; i++) {
            address member = _classMembers[i];
            classMembers[member] = true;
        }
        administrator = msg.sender;

        classCounsel = _classCounsel;

        fundAmount = _fundAmount;
    }

    //Some functions won't work without contract address
    modifier contractAddressIsSet() {
      require(
         contractAddress != address(0),
         "There is no address set for this contract, so it can't process funds."
      );
      _;
   }

    modifier isAdmin() {
        require(
            msg.sender == administrator,
            "You must be the admin to access this function."
        );
        _;
    }

    modifier fundIsOpen() {
        require(
            fundIsClosed == false,
            "The fund is no longer open."
        );
        _;
    }

    //is there a native solidity function to get a contract's address?
    function setContractAddress(address _contractAddress) public isAdmin fundIsOpen {
        contractAddress = _contractAddress;
    }

    //IRL, would probably want to refund any extra money accidentally sent by defendant
    function sendFunds() public payable fundIsOpen {

    }

    function submitClaim() public fundIsOpen {
        require(classMembers[msg.sender] == true, "You must be a settlement class member to submit a claim.");

        //IRL, there is usually more criteria than being on a list of potential class members
        claimants.push(msg.sender);
    }

    function disburseFunds() public payable contractAddressIsSet isAdmin fundIsOpen {

        require(contractAddress.balance >= fundAmount, "It's not time to disburse because there are still funds that need to be submitted.");

        uint256 classPayments;

        classPayments = contractAddress.balance - attyFees;

        uint256 proRata;

        proRata = classPayments / claimants.length;

        for(uint i = 0; i < claimants.length; i++) {
            address recipient = claimants[i];
            payable(recipient).transfer(proRata);
        }

        payable(classCounsel).transfer(attyFees);

        fundIsClosed = true;

    }

    function getFundAmount() public view contractAddressIsSet returns(uint256) {
        return contractAddress.balance;
    }

    function getClaimants() private view isAdmin returns(address[] memory) {
        return claimants;
    }

}
