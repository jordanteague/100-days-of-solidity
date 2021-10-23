// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./LexOwnable.sol";
import {MerkleProof} from "./MerkleProof.sol";

/// @notice Function whitelisting contract.
abstract contract LexWhiteListableMerkle is LexOwnable {

    using MerkleProof for bytes32[];

    event ToggleWhiteList(bool indexed whitelistEnabled);
    event UpdateWhitelist(address indexed account, bool indexed whitelisted);

    bool public whitelistEnabled;
    mapping(address => bool) public whitelisted;
    bytes32 merkleRoot;

    /// @notice Initialize contract with `whitelistEnabled` status.
    constructor(bool _whitelistEnabled, address _owner) LexOwnable(_owner) {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }

    /// @notice Whitelisting modifier that conditions modified function to be called between `whitelisted` accounts.
    modifier onlyWhitelisted(address from, address to) {
        if (whitelistEnabled)
        require(whitelisted[from] && whitelisted[to], "NOT_WHITELISTED");
        _;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function claimWhiteList(bytes32[] memory proof) public {
        require(merkleRoot != 0, "Not time to make a claim");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the whitelist");
        whitelisted[msg.sender] = true;
        emit UpdateWhitelist(msg.sender, true);
     }

    /// @notice Update account `whitelisted` status.
    /// @param account Account to update.
    /// @param _whitelisted If 'true', `account` is `whitelisted`.
    function updateWhitelist(address account, bool _whitelisted) external onlyOwner {
        whitelisted[account] = _whitelisted;
        emit UpdateWhitelist(account, _whitelisted);
    }

    /// @notice Toggle `whitelisted` conditions on/off.
    /// @param _whitelistEnabled If 'true', `whitelisted` conditions are on.
    function toggleWhitelist(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
        emit ToggleWhiteList(_whitelistEnabled);
    }
}
