//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//This is a demo for a contract term bank.  Could be within a law firm, a state bar, an interest group, or nationwide.
//The purpose is to create an agreed-on bank of contract terms with unique identifiers that can be used across smart contracts.
//The voting system in this demo is pretty simple and could certainly be expounded upon.

contract OpenContract {

    event proposalCreated(Term _proposedTerm, address _proposer);
    event votingOpen(Proposal _proposal);
    event votingClosed(Proposal _proposal);
    event termAdded(Term _term);

    struct Term {
        string shortDescription;
        string longDescription;
        bytes32 id; //unique id from hash
    }

    Term[] public termBank;

    struct Proposal {
        Term proposedTerm;
        address proposer;
        bool votingStarted;
        bool votingClosed;
        uint256 votes;
    }

    mapping(bytes32 => mapping(address => bool)) public votes;

    Proposal[] public proposals;

    address public superadmin;

    mapping(address => bool) public voters;

    uint256 public votersCount;

    constructor() {
        superadmin = msg.sender;
    }

    modifier mustBeSuperAdmin() {
        require(msg.sender == superadmin, "Only the superadmin may access this function");
        _;
    }

    function addVoter(address _voter) public {
        require(voters[_voter] == false);
        voters[_voter] = true;
        votersCount++;
    }

    function proposeTerm(string memory _shortDescription, string memory _longDescription) public {

        Term memory _proposedTerm = Term({
            shortDescription: _shortDescription,
            longDescription: _longDescription,
            id: keccak256(abi.encodePacked(_shortDescription))
        });

        Proposal memory proposal = Proposal({
            proposedTerm: _proposedTerm,
            proposer: msg.sender,
            votingStarted: false,
            votingClosed: false,
            votes: 0
        });

        proposals.push(proposal);

        emit proposalCreated(_proposedTerm, msg.sender);
    }

    function countProposals() public view returns(uint256) {
        return proposals.length;
    }

    function openVoting(uint256 _id) public mustBeSuperAdmin {
        require(proposals[_id].votingStarted == false, "Voting has already started");
        require(proposals[_id].votingClosed == false, "Voting has closed");
        proposals[_id].votingStarted = true;
        emit votingOpen(proposals[_id]);
    }

    function closeVoting(uint256 _id) public mustBeSuperAdmin {
        require(proposals[_id].votingStarted == true, "Voting has not started yet");
        require(proposals[_id].votingClosed == false, "Voting has already closed");
        Proposal storage _proposal = proposals[_id];
        _proposal.votingClosed = true;
        emit votingClosed(proposals[_id]);
        if(_proposal.votes == votersCount) { //case: unanimous votes, need to revise to be just majoirty
            termBank.push(_proposal.proposedTerm);
            emit termAdded(_proposal.proposedTerm);
        }
    }

    function voteOnTerm(uint256 _id, bool _vote) public {
        require(voters[msg.sender] == true, "You are not eligble to vote");
        Proposal storage _proposal = proposals[_id];
        require(votes[_proposal.proposedTerm.id][msg.sender] == false, "You already voted");

        if(_vote == true) {
            _proposal.votes++;
        }
        votes[_proposal.proposedTerm.id][msg.sender] = true;
    }

}
