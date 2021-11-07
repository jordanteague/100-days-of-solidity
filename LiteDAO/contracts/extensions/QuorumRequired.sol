// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import '../LiteDAO.sol';

contract QuorumRequired is LiteDAO {

    constructor(uint256 votingPeriod_) LiteDAO(votingPeriod_) {

    }

    function _weighVotes(uint256 yesVotes, uint256 noVotes) internal override returns(bool didProposalPass) {
        // requires minimum of 50% available votes cast

        uint256 quorum = (voteToken.totalSupply() / 2);
        uint256 votes = yesVotes + noVotes;
        require(votes >= quorum, "QUORUM_REQUIRED");

        if(yesVotes > noVotes) {
            didProposalPass = true;
        }

    }

}
