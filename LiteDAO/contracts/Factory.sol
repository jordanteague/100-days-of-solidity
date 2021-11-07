// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './LexOwnable.sol';
import './LiteDAO.sol';
import './VoteToken.sol';
import './extensions/QuorumRequired.sol';

contract DaoFactory is LexOwnable {
    address[] public daoRegistry;
    mapping(address => VoteType) public voteType;

    enum VoteType {
        SIMPLE_MAJORITY,
        SIMPLE_MAJORITY_QUORUM_REQUIRED
    }

    constructor() LexOwnable(msg.sender) {

    }

    function deployDAO(
          uint256 votingPeriod_,
          string memory name_,
          string memory symbol_,
          bool paused_,
          address[] memory voters_,
          uint256[] memory shares_,
          VoteType voteType_
      ) external onlyOwner {

        if(voteType_==VoteType.SIMPLE_MAJORITY) {
            LiteDAO dao_ = new LiteDAO(votingPeriod_);
            daoRegistry.push(address(dao_));
            VoteToken voteToken_ = new VoteToken(name_, symbol_, address(dao_), paused_, voters_, shares_);
            dao_.setVoteToken(IVoteToken(address(voteToken_)));
            voteType[address(dao_)] = voteType_;
        }

        if(voteType_==VoteType.SIMPLE_MAJORITY_QUORUM_REQUIRED) {
            QuorumRequired dao_ = new QuorumRequired(votingPeriod_);
            daoRegistry.push(address(dao_));
            VoteToken voteToken_ = new VoteToken(name_, symbol_, address(dao_), paused_, voters_, shares_);
            dao_.setVoteToken(IVoteToken(address(voteToken_)));
            voteType[address(dao_)] = voteType_;
        }


    }

}
