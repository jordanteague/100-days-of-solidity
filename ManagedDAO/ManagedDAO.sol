// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

//Experimenting with smart contracts as self-contained manager-managed LLCs

contract ManagedDAO {

    event paymentMade(address payable _address, string _reason);

    // all variables public for ease of testing; would likely want many of these to be accessible by members only

    address public manager; // manager of manager-managed LLC
    uint public totalShares; // increments/decrements when members added/removed
    string public legalName; // in this example, this is contract address
    string public jurisdiction; // jurisdiction where registered. formatted however - enough to put third parties on notice.
    mapping(address => Member) public members; // in this example, every DAO member is an LLC member - reflect this in operating agreement
    address[] public memberList; // historical list - doesn't change if members deleted
    string public operatingAgreement;
    uint public perShareValue;
    uint public votingPeriod; //standard time voting period remains open

    string[] public proposalTypes = ['newMember', 'kickMember', 'newManager', 'kickManager'];

    struct Member {
        uint shares;
        uint contribution;
        bool approved; // this struct starts out as a proposal
        bool kicked;
    }

    struct Proposal { // vote proposal to add/remove member/manager
        uint proposalType;
        address proposer;
        address voteSubject; // member or manager, depending on proposal type
        uint deadline; // date of proposal + votingPeriod
        uint256 yesVotes;
        uint256 noVotes;
        bool executed; // any member can trigger once voting period has ended
    }

    Proposal[] public proposals;

    mapping(uint256 => mapping(address => bool)) public voted;

    ///// MODIFIERS /////

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender].approved == true, "You are not a member");
        _;
    }

    ///// TREASURY RELATED /////
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // FOR TESTING
    // ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]

    constructor(
            string memory _jurisdiction,
            uint _perShareValue,
            string memory _legalName
        ) {
        manager = msg.sender;
        jurisdiction = _jurisdiction;
        legalName = _legalName;
        perShareValue = _perShareValue; //amt required to buy a share

    }

    ///// NEW MEMBER JOIN /////
    function requestMembership(uint _shares) external payable {
        uint _requiredContribution = _shares * perShareValue;
        require(msg.value >= _requiredContribution, "You must contribute at least the required amount");
        (bool sent, bytes memory data) = payable(address(this)).call{value: msg.value}(""); // better to send to an "escrow" account pending voteSubject?
        require(sent, "Failed to send Ether");
        _proposeMember(msg.sender, _shares, msg.value);
    }

    ///// MANAGER FUNCTIONS /////

    function managerSpend(address _address, uint _amount, string memory _reason) external onlyManager {
        _spend(_address, _amount, _reason);
    }

    function managerSign() public onlyManager {
        // authorize manager to sign something on behalf of the smart contract?
    }

    function distributions(uint _total) public payable onlyManager {
        require(_total <= address(this).balance, "insufficient balance");

        uint _perShare = _total / totalShares;

        for(uint i = 0; i < memberList.length; i++) {
            address _member = memberList[i];
            if(members[_member].approved == true) {
                uint _amount = members[_member].shares * _perShare;
                _spend(_member, _amount, "distribution");
            }
        }
    }

    function managerResign() public onlyManager {
        manager = address(0);
    }

    ///// MEMBER FUNCTIONS /////

    function proposeKickManager() public onlyMembers {
        require(manager != address(0), "There is no manager to kick");
        Proposal memory _proposal = Proposal({
            proposalType: 4,
            proposer: msg.sender,
            voteSubject: manager,
            deadline: block.timestamp + (votingPeriod * 1 days),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        proposals.push(_proposal);
    }

    function proposeNewManager(address _manager) public onlyMembers {
        require(manager != address(0), "You must remove manager before appointing a new one");
        Proposal memory _proposal = Proposal({
            proposalType: 3,
            proposer: msg.sender,
            voteSubject: _manager,
            deadline: block.timestamp + (votingPeriod * 1 days),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        proposals.push(_proposal);
    }

    function memberVote(uint _proposalId, bool _vote) public onlyMembers {
        require(voted[_proposalId][msg.sender] == false, "You already voted");
        require(proposals[_proposalId].deadline >= block.timestamp, "The voting period has ended");

        if(_vote == true) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }

        voted[_proposalId][msg.sender] = true;
    }

    function executeVote(uint256 _proposalId) public {
        require(msg.sender == manager || members[msg.sender].approved == true, "You must be the manager or a member");
        Proposal memory _proposal = proposals[_proposalId];
        require(_proposal.deadline < block.timestamp, "The voting period hasn't ended");
        require(_proposal.executed == false, "This vote has already been executed");
        // add logic to require a quorum?

        bool passed = false;
        if(_proposal.yesVotes > _proposal.noVotes) {
            passed = true;
        }

        address _address = _proposal.voteSubject;
        uint _type = _proposal.proposalType;

        if(_type == 1) { // new member
           if(passed = true) {
                _addMember(_address);
           } else {
               _spend(payable(_address), members[_address].contribution, "member proposal failed");
           }
        }
        if(_type == 2) { // member kick
           if(passed = true) {
                _removeMember(_address);
           } else {
                // nothing
           }
        }
        if(_type == 3) { // new manager
           if(passed = true) {
                manager = _address;
           } else {
               // nothing
           }
        }
        if(_type == 4) { // manager kick
           if(passed = true) {
                manager = address(0);
           } else {
               //nothing
           }
        }

        if(_proposal.yesVotes > _proposal.noVotes) {
            if(_proposal.proposalType == 4) {
                manager = address(0);
            } else if(_proposal.proposalType == 3) { // appoint new manager
                manager = proposals[_proposalId].voteSubject;
            } else if(_proposal.proposalType == 1) { // add new member

            } else if(_proposal.proposalType == 2) { // kick member
                address _member = _proposal.voteSubject;
                _removeMember(_member);
            }
        }

        proposals[_proposalId].executed = true;

    }

    ///// INTERNAL FUNCTIONS /////

    function _proposeMember (
        address _address,
        uint _shares,
        uint _contribution
      ) internal {
        //must either be initial members, OR consent of majority members
        require(members[_address].approved == false, "already a member");

        Member memory _member = Member({
            shares: _shares,
            contribution: _contribution,
            approved: false,
            kicked: false
          });
        members[_address] = _member;

        // Add proposal for new member
        Proposal memory _proposal = Proposal({
            proposalType: 1,
            proposer: msg.sender,
            voteSubject: _address,
            deadline: block.timestamp + (votingPeriod * 1 days),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        proposals.push(_proposal);

    }

    function _addMember(address _member) internal {
        uint _shares = members[_member].shares;
        totalShares += _shares;
        members[_member].approved = true; // member still needs to make contribution
    }

    function _removeMember(address _member) internal {
        uint _shares = members[_member].shares;
        members[_member].approved = false;
        members[_member].kicked = true;
        totalShares -= _shares;
        _spend(_member, members[_member].contribution / 2, "Member kicked out"); // arbitrary return of 50% of funds if kicked
    }

    function _spend(address _address, uint _amount, string memory _reason) internal {
        require(address(this).balance >= _amount, "insufficient funds");
        payable(address(_address)).transfer(_amount);
        emit paymentMade(payable(_address), _reason);
    }

}
