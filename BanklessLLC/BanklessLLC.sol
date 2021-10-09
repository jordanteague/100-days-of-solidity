// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

//Experimenting with smart contracts as self-contained manager-managed LLCs
//Needs to include some voting functionality for issues where member vote is required
//A little different than a DAO, and also different than the Ricardian LLC tokenized Series concept
//What if the company was registered wtih secretary of state as <ETH-ADDRESS-LLC>?

contract BanklessLLC {

    event timeToIncorporate(address _contractAddress); //listener files paperwork with SOS
    event paymentMade(address _address, uint _amount, string _reason);
    event distributionsApproved(uint _amount);
    event distributionClaimed(address _address, uint _amount);

    address public manager; //sort of like the organizer, but will also administrate the smart contract
    uint public totalShares;
    address public legalName; //in this example, this is the contract address. basically guaranteed not to be taken.
    string public jurisdiction;
    bool public isIncorporated; //is formally incorporated with SOS
    string public articlesURI; //put articles of org somewhere like IPFS
    mapping(address => Member) public members;
    address[] public memberList;
    uint perShareValue;
    mapping(address => uint) public unclaimedDistributions;

    struct Member {
        string first;
        string last;
        uint shares;
        uint requiredContribution;
        uint contribution;
        bool isApproved; //members agree to let them in
        bool isAdmitted; //they've paid their capital contribution and haven't been kicked
    }

    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].isAdmitted == true, "You are not a member");
        _;
    }

    modifier memberMustBeAdmitted() {
        require(members[msg.sender].isAdmitted == true);
        _;
    }

    ///FOR TESTING
    /// ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]
    /// ["Susan","Bob"]
    /// ["Doe","Smith"]
    /// [10,10]

    constructor(
            string memory _jurisdiction,
            uint _perShareValue,
            address[] memory _addresses,
            string[] memory _firsts,
            string[] memory _lasts,
            uint[] memory _allShares
        ) {
        manager = msg.sender;
        jurisdiction = _jurisdiction;
        legalName = address(this);
        //treasury = payable(address(this)); //initially, the contract; can change
        emit timeToIncorporate(legalName); //reminder to file with SOS
        uint _length = _firsts.length;
        perShareValue = _perShareValue; //amt required to buy a share

        //add initial members
        require(_lasts.length == _length && _addresses.length == _length && _allShares.length == _length);

        for(uint i = 0; i < _firsts.length; i++) {

            address _address = _addresses[i];
            string memory _first = _firsts[i];
            string memory _last = _lasts[i];
            uint _shares = _allShares[i];
            uint _requiredContribution = _shares * perShareValue;
            bool _isApproved = true;

            _addMember(_address, _first, _last, _shares, _requiredContribution, _isApproved);
        }
    }

    function incorporated(string memory _articlesURI) public onlyManager {
        articlesURI = _articlesURI;
        isIncorporated = true;
    }

    function managerResign() public onlyManager {
        //needs to give members power to appoint a new manager
    }

    function managerKick() public onlyManager {
        //needs to give members power to appoint a new manager
    }

    function _addMember (
        address _address,
        string memory _first,
        string memory _last,
        uint _shares,
        uint _requiredContribution,
        bool _isApproved
      ) internal {
        //must either be initial members, OR consent of majority members
        require(members[_address].isApproved == false, "already a member");

        Member memory _member = Member({
            first: _first,
            last: _last,
            shares: _shares,
            requiredContribution: _requiredContribution,
            contribution: 0,
            isApproved: _isApproved,
            isAdmitted: false //not until they pay capital contribution
          });
        members[_address] = _member;
        memberList.push(_address);
        totalShares += _shares;
    }

    //as written, this would not confer additional shares for excess contributions
    function memberContribute() public payable {
        require(members[msg.sender].isApproved == true, "You are not a member or pending member");
        (bool sent, bytes memory data) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        members[msg.sender].contribution += msg.value;
        if(members[msg.sender].contribution >= members[msg.sender].requiredContribution) {
            members[msg.sender].isAdmitted = true;
        }
    }

    //in this example, manager has complete discretion to spend company funds so long as they're manager
    function managerPayBills(address payable _address, string memory _reason) public payable onlyManager {
        payable(address(_address)).transfer(msg.value);
        emit paymentMade(_address, msg.value, _reason);
    }

    function setDistributions(uint _total) public onlyManager { //assuming manager gets to decide
        require(_total <= address(this).balance, "insufficient balance");

        for(uint i = 0; i < memberList.length; i++) {
            address _member = memberList[i];
            uint _perShare = _total / totalShares;
            uint _amount = members[_member].shares * _perShare;
            unclaimedDistributions[memberList[i]] = _amount;
        }
    }

    function claimDistribution() memberMustBeAdmitted public payable {
        uint _amount = unclaimedDistributions[msg.sender]; //this would get voted on
        require(_amount > 0, "There is nothing to distribute to you");
        require(address(this).balance >= _amount, "Insufficient funds in contract");
        payable(address(msg.sender)).transfer(_amount);
        unclaimedDistributions[msg.sender] = 0;
    }

}
