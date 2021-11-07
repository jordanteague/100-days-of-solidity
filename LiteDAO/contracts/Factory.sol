// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './LexOwnable.sol';
import './LiteDAO.sol';
import './VoteToken.sol';

contract DaoFactory is LexOwnable {
    address[] public daoRegistry;

    constructor() LexOwnable(msg.sender) {

    }

    function deployDAO(
          uint256 votingPeriod_,
          string memory name_,
          string memory symbol_,
          bool paused_,
          address[] memory voters_,
          uint256[] memory shares_
      ) external onlyOwner {
        LiteDAO liteDAO_ = new LiteDAO(votingPeriod_);
        daoRegistry.push(address(liteDAO_));
        VoteToken voteToken_ = new VoteToken(name_, symbol_, address(liteDAO_), paused_, voters_, shares_);
        liteDAO_.setVoteToken(IVoteToken(address(voteToken_)));
    }

}
