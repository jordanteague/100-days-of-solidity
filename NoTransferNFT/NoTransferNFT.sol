// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation.
/// @author adapted from LexToken: https://github.com/lexDAO/LexCorpus/blob/master/contracts/token/erc721/LexNFT.sol
/// @author NFTs intended to be immutably non-transferable, such as in case of a token representing a professional license
/// @author tokens can be burned and new ones minted in case of loss of access
/// @author appears the Non-Transferable Token standard hasn't taken off, and this would be wallet compatible

import './LexOwnable.sol';

contract NoTransferNFT is LexOwnable {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;

    uint256 public totalSupply;

    uint public idCount;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    uint256 internal immutable DOMAIN_SEPARATOR_CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;
    mapping(address => uint256) public noncesForAll;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _idCount
    ) {
        name = _name;
        symbol = _symbol;

        DOMAIN_SEPARATOR_CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator();

        idCount = _idCount;

    }

    function _calculateDomainSeparator() internal view returns (bytes32 domainSeperator) {
        domainSeperator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeperator) {
        domainSeperator = block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator();
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function approve(address spender, uint256 tokenId) external { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function setApprovalForAll(address operator, bool approved) external { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function transfer(address to, uint256 tokenId) external { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function transferFrom(address, address to, uint256 tokenId) public { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function safeTransferFrom(address, address to, uint256 tokenId) external { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public { //here only to remain EIP-721 compliant
        revert("This is a non-transferable NFT");
    }

    function mint(address to, string memory _tokenURI) public onlyOwner {
        uint tokenId = idCount;

        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        // This is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits,
        // and because the sum of all user balances can't exceed type(uint256).max!
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;

        tokenURI[tokenId] = _tokenURI;

        idCount++;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        address owner = ownerOf[tokenId];

        require(ownerOf[tokenId] != address(0), "NOT_MINTED");

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[tokenId];

        delete tokenURI[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}
