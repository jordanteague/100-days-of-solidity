// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './LexOwnable.sol';
import './LiteDAO.sol';

/// @notice Factory to deploy LiteDAO.
contract DaoFactory is LexOwnable {
    address[] public daoRegistry;

    constructor() LexOwnable(msg.sender) {

    }

    function deployDAO(
        string memory name_,
        string memory symbol_,
        bool paused_,
        address[] memory voters,
        uint256[] memory shares,
        uint256 votingPeriod_,
        uint256 quorum_,
        uint256 supermajority_
      ) external onlyOwner {
        LiteDAO dao_ = new LiteDAO(name_, symbol_, paused_, voters, shares, votingPeriod_, quorum_, supermajority_);
        daoRegistry.push(address(dao_));
    }

}
