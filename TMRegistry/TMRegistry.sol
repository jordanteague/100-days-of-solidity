// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import './LexNFT.sol';
import './LexPausable.sol';

// the goal: on-chain verification of off-chain TM ownership
// (this is a bridge, with hope that oneday TM registration comes onchain entirely)
// applicant pays fee, both as a revenue generator, and also a spam prevention device
// to verify identity, a secret is mailed or emailed to address on file with TM authority
// snail mail may actually be best since it's inefficient to hack (can be done via API)
// owner has deadline to verify wallet with secret sent to them, or else, app lapses
// currently, TMNFT is 100% transferrable - if transfer is a hack, dispute can be filed and NFT can potentially be burned

contract TMRegistry is LexNFT, LexPausable {
    event NewApplication(address, uint);
    event MarkVerified(address, uint);
    event NewDispute(uint, string);
    event RevokedMark(uint);

    uint fee; // for applications and disputes; currently ETH only; maybe token is better
    uint appCount;
    uint appDeadline;
    uint disputeCount;

    bytes32 GLOBAL_SECRET;

    string globalTokenURI;

    enum Jurisdiction {
        UNITED_STATES // this can obviously be expanded
    }

    struct Mark {
        string wordMark; // if not work mark, empty
        string stylizedMark; // if stylized mark, uri for ipfs (will be rejected otherwise); else, empty
        Jurisdiction jurisdiction;
        string regNumber; //  may not always be integer
    }

    /// * MAPPINGS PUBLIC FOR TESTING ONLY * ///
    mapping(uint => Mark) public marks; // tokenId => Mark
    mapping(uint => Mark) public applications; // appNum => Mark
    mapping(uint => address) public applicants; // appNum => applicant;
    mapping(uint => uint) public appDeadlines; // appNumber => deadline (unix)
    mapping(uint => uint) public disputes; // disputeNum => markNum
    mapping(uint => string) public disputeDetails; // disputeNum => explanation
    mapping(uint => address) public disputors; // disputeNum => disputor

    /// * MOST VALUES HARD-CODED FOR TESTING ONLY * ///
    constructor(string memory secret_)
    LexNFT("NFTrademarks", "NFTM") LexPausable(false, msg.sender) {
        GLOBAL_SECRET = keccak256(abi.encodePacked(secret_));
        globalTokenURI = "ipfs://test";
        fee = 1; // 1 wei, for testing
        appDeadline = 30; // 30 days to verify
    }

    function submitApplication(
            string memory wordMark_,
            string memory stylizedMark_,
            string memory regNumber_
        ) external payable notPaused {

        require(msg.value == fee, "You must submit the correct fee");

        Mark memory mark = Mark({
           wordMark: wordMark_,
           stylizedMark: stylizedMark_,
           jurisdiction: Jurisdiction.UNITED_STATES, // hard coded for now
           regNumber: regNumber_
        });

        applications[appCount] = mark;
        applicants[appCount] = msg.sender;
        appDeadlines[appCount] = block.timestamp + (appDeadline * 1 days);

        emit NewApplication(msg.sender, appCount);
        appCount++;
    }

    function verifyMark(uint app_, bytes32 secret_) external {
        require(appDeadlines[app_] > block.timestamp, "Your deadline to verify has passed");
        require(applicants[app_] == msg.sender, "You are not authorized to verify");
        // CURRENTLY UNSECURE - PUBLIC FOR TESTING ONLY!
        require(secret_ == this.generateAppSecret(msg.sender), "You are not authorized to verify");

        address applicant_ = msg.sender;
        _mint(applicant_, app_, globalTokenURI); // could be cool to make tokenURI = stylizedMark, if mark is stylized
        marks[app_] = applications[app_];
        delete applications[app_];
        delete applicants[app_];
        delete appDeadlines[app_]; // currently, apps that don't get verified will never be deleted

        emit MarkVerified(applicant_, app_);
    }

    /// * DISPUTES * ///

    function dispute(uint mark_, string memory description_) external payable {
        // make this payable to avoid spam
        // considered storing in events only, but ability to delete fraudulent disputes may be important
        require(msg.value == fee, "You must submit the correct fee");
        disputes[disputeCount] = mark_;
        disputors[disputeCount] = msg.sender;
        disputeDetails[disputeCount] = description_;

        emit NewDispute(mark_, description_);
        disputeCount++;
    }

    /// * ADMIN FUNCTIONS * ///

    function changeGlobalSecret(string memory secret_) external onlyOwner {
        GLOBAL_SECRET = keccak256(abi.encodePacked(secret_));
    }

    function changeAppDeadline(uint appDeadline_) external onlyOwner {
        appDeadline = appDeadline_;
    }

    function revoke(uint mark_) external onlyOwner {
        _burn(mark_);
        delete marks[mark_];
        emit RevokedMark(mark_);
    }

    function deleteDispute(uint dispute_) external onlyOwner {
        delete disputes[dispute_];
        delete disputors[dispute_];
        delete disputeDetails[dispute_];
    }

    /// * VIEW FUNCTIONS FOR TESTING ONLY! NOT SECURE! * ///

    function generateAppSecret(address address_) external view returns(bytes32) {
        bytes32 APP_SECRET = keccak256(abi.encodePacked(
            GLOBAL_SECRET,
            address_
        ));
        return APP_SECRET;
    }

    function viewGlobalSecret() external view returns(bytes32) {
        return GLOBAL_SECRET;
    }

}
