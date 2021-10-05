// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

contract TokenAddressFinder {

    mapping(string => address) public tokens;

    address public admin; //@dev LexDAO Gnosis vault?

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor(address admin_) {
        admin = admin_; //@dev in case deployer shouldn't be sole admin (DAO, vault, etc.)
    }

    //@dev to keep things simple, no case control. just enter all lowercase. (or case control in a UX)
    function addToken(string memory symbol_, address tokenAddress_) public onlyAdmin {
       tokens[symbol_]  = tokenAddress_; //@dev immutable, no way to change address or delete token once added
    }

    function getTokenAddress(string memory symbol_) external view returns(address _tokenAddress) {
        require(tokens[symbol_] != address(0), "This token does not exist, try entering in all lowercase");
        _tokenAddress = tokens[symbol_];
        return _tokenAddress;
    }

}
