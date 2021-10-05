// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

contract TokenFinder {
    address public lexDAO;

    mapping(string => address) public tokens;

    modifier onlyLexDAO {
        require(msg.sender == lexDAO);
        _;
    }

    constructor(address lexDAO_) {
        lexDAO = lexDAO_;
    }

    /// @dev To keep things simple, no case control - just enter all lowercase (or case control in a UX).
    function addToken(string calldata symbol_, address tokenAddress_) external onlyLexDAO {
        tokens[symbol_] = tokenAddress_;
    }

    function getToken(string calldata symbol_) external view returns (address tokenAddress) {
        require(tokens[symbol_] != address(0), "This token does not exist, try entering in all uppercase or all lowercase");
        tokenAddress = tokens[symbol_];
    }

    /// @notice Protocol for LexDAO to update role.
    /// @param _lexDAO Account to assign role to.
    function updateLexDAO(address _lexDAO) external onlyLexDAO {
        lexDAO = _lexDAO;
    }
}
