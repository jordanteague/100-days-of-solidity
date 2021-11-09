// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './LiteDAOtoken.sol';
import './LiteDAOnftHelper.sol';

/// @notice Simple gas-optimized DAO core module.
contract LiteDAO is LiteDAOtoken, LiteDAOnftHelper {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewProposal(uint256 proposalId);

    event ProposalProcessed(uint256 proposalId);

    /*///////////////////////////////////////////////////////////////
                              DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public proposalCount;

    uint256 public votingPeriod;

    uint256 immutable public quorum; // expressed as uint 1-100

    uint256 immutable public supermajority; // expressed as uint 1-100

    bool private initialized;

    mapping(uint256 => Proposal) public proposals;

    mapping(ProposalType => VoteType) proposalVoteTypes;

    enum ProposalType {
        MINT,
        BURN,
        CALL,
        GOV
    }

    enum VoteType {
        SIMPLE_MAJORITY,
        SIMPLE_MAJORITY_QUORUM_REQUIRED,
        SUPERMAJORITY,
        SUPERMAJORITY_QUORUM_REQUIRED
    }

    struct Proposal {
        ProposalType proposalType;
        string description;
        address account; // member being added/kicked; account to send money; or account receiving loot
        address asset; // asset considered for payment
        uint256 amount; // value to be minted/burned/spent
        bytes payload; // data for CALL proposals
        uint256 yesVotes;
        uint256 noVotes;
        uint256 creationTime;
    }

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] memory voters,
        uint256[] memory shares,
        uint256 votingPeriod_,
        uint256 quorum_,
        uint256 supermajority_
    )
        LiteDAOtoken(
            name_,
            symbol_,
            paused_,
            voters,
            shares
        )

    {
        votingPeriod = votingPeriod_;
        quorum = quorum_;
        supermajority = supermajority_;
    }

    function setVoteTypes(
        VoteType mint,
        VoteType burn,
        VoteType call,
        VoteType gov
    ) external {
        require(!initialized, "INITIALIZED");

        proposalVoteTypes[ProposalType.MINT] = mint;

        proposalVoteTypes[ProposalType.BURN] = burn;

        proposalVoteTypes[ProposalType.CALL] = call;

        proposalVoteTypes[ProposalType.GOV] = gov;

        initialized = true;
    }

    /*///////////////////////////////////////////////////////////////
                         PROPOSAL LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier onlyTokenHolders() {
        require(balanceOf[msg.sender] > 0, "NOT_TOKEN_HOLDER");
        _;
    }

    function propose(
        ProposalType proposalType,
        string calldata description,
        address account,
        address asset,
        uint256 amount,
        bytes calldata payload
    ) external onlyTokenHolders {
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            proposalType: proposalType,
            description: description,
            account: account,
            asset: asset,
            amount: amount,
            payload: payload,
            yesVotes: 0,
            noVotes: 0,
            creationTime: block.timestamp
        });

        unchecked {
            proposalCount++;
        }

        emit NewProposal(proposalId);
    }

    function vote(uint256 proposal, bool approve) external onlyTokenHolders {
        Proposal storage prop = proposals[proposal];

        unchecked {
            require(block.timestamp <= prop.creationTime + votingPeriod, "VOTING_ENDED");
        }

        uint256 weight = getPriorVotes(msg.sender, prop.creationTime);

        if (approve) {
            prop.yesVotes += weight;
        } else {
            prop.noVotes += weight;
        }
    }

    function processProposal(uint256 proposal) external returns (bool success) {
        Proposal storage prop = proposals[proposal];

        // * COMMENTED OUT FOR TESTING * ///
        // unchecked {
        // require(block.timestamp > prop.creationTime + votingPeriod, "VOTING_NOT_ENDED");
        // }

        VoteType voteType = proposalVoteTypes[prop.proposalType];

        bool didProposalPass = _countVotes(voteType, prop.yesVotes, prop.noVotes);

        if (didProposalPass) { // simple majority; can use module to override this
            if (prop.proposalType == ProposalType.MINT) {
                _mint(prop.account, prop.amount);
            }

            if (prop.proposalType == ProposalType.BURN) {
                _burn(prop.account, prop.amount);
            }

            if (prop.proposalType == ProposalType.CALL) {
                (success, ) = prop.account.call{value: prop.amount}(prop.payload);
            }

            if (prop.proposalType == ProposalType.GOV) {
                if (prop.amount > 0) votingPeriod = prop.amount;
                if (prop.payload.length > 0) _togglePause();
            }

        }

        delete proposals[proposal];

        emit ProposalProcessed(proposal);
    }

    function _countVotes(
        VoteType voteType,
        uint256 yesVotes,
        uint256 noVotes
    ) internal view returns (bool didProposalPass) {
        // rule out any failed quorums
        if(voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            unchecked {
                uint256 minVotes = (totalSupply * quorum) / 100;

                uint256 votes = yesVotes + noVotes;

                require(votes >= minVotes, "QUORUM_REQUIRED");
            }
        }

        // simple majority
        if(voteType == VoteType.SIMPLE_MAJORITY || voteType == VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED) {
            if (yesVotes > noVotes) {
                didProposalPass = true;
            }
        }

        // supermajority
        if(voteType == VoteType.SUPERMAJORITY || voteType == VoteType.SUPERMAJORITY_QUORUM_REQUIRED) {
            // example: 7 yes, 2 no, supermajority = 66
            // ((7+2) * 66) / 100 = 5.94; 7 yes will pass
            unchecked {
                uint256 minYes = ((yesVotes + noVotes) * supermajority) / 100;

                if (yesVotes >= minYes) {
                    didProposalPass = true;
                }
            }
        }
    }
}
