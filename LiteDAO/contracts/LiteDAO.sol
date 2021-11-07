// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Vote Token interface.
interface IVoteToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getPriorVotes(address account, uint256 timestamp) external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

/// @notice Minimalist DAO core module.
contract LiteDAO {
    event NewProposal(uint256 proposalId);

    event ProposalProcessed(uint256 proposalId);

    uint256 public proposalCount;

    uint256 public votingPeriod;

    IVoteToken public voteToken;

    mapping(uint256 => Proposal) public proposals;

    enum ProposalType {
        MINT,
        BURN,
        SPEND,
        CALL
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

    constructor(uint256 votingPeriod_) {
        votingPeriod = votingPeriod_;
    }

    function setVoteToken(IVoteToken voteToken_) external {
        require(address(voteToken)==address(0), "VOTETOKEN_ALREADY_SET");
        voteToken = voteToken_;
    }

    /*///////////////////////////////////////////////////////////////
                         PROPOSAL LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier onlyTokenHolders() {
        require(voteToken.balanceOf(msg.sender) > 0, "NOT_TOKEN_HOLDER");
        _;
    }

    function propose(ProposalType proposalType, string memory description, address account, address asset, uint256 amount, bytes memory payload) external onlyTokenHolders {
        Proposal memory proposal = Proposal({
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

        proposals[proposalCount] = proposal;

        emit NewProposal(proposalCount);

        proposalCount++;
    }

    function vote(uint256 proposal, bool approve) external onlyTokenHolders {
        Proposal storage prop = proposals[proposal];

        require(prop.creationTime + (votingPeriod * 1 days) >= block.timestamp, "VOTING_ENDED");

        uint256 weight = voteToken.getPriorVotes(msg.sender, prop.creationTime);

        if (approve) {
            prop.yesVotes += weight;
        } else {
            prop.noVotes += weight;
        }
    }

    function processProposal(uint256 proposal) external onlyTokenHolders {
        Proposal storage prop = proposals[proposal];

        require(prop.creationTime + (votingPeriod * 1 days) < block.timestamp, "VOTING_NOT_ENDED");

        bool didProposalPass = _weighVotes(prop.yesVotes, prop.noVotes, voteToken.totalSupply());

        if(didProposalPass) { // simple majority; can create module to override this

            address account = prop.account;

            if (prop.proposalType == ProposalType.MINT) {
                voteToken.mint(prop.account, prop.amount);
            }

            if (prop.proposalType == ProposalType.BURN) {
                voteToken.burn(prop.account, prop.amount);
            }

            if (prop.proposalType == ProposalType.SPEND) {
                safeTransfer(prop.asset, prop.account, prop.amount);
            }

            if (prop.proposalType == ProposalType.CALL) {
                account.call{value: prop.amount}(prop.payload);
            }

        }

        delete proposals[proposal];

        emit ProposalProcessed(proposal);
    }

    function _weighVotes(uint256 yesVotes, uint256 noVotes, uint256 totalSupply) internal virtual returns(bool didProposalPass) {

        if(yesVotes > noVotes) {
            didProposalPass = true;
        }

    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // We'll use 4 + 32 * 2 bytes.
            let callDataLength := 68

            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Update the free memory pointer for safety.
            mstore(0x40, add(freeMemoryPointer, callDataLength))

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, shl(224, 0xa9059cbb)) // Properly shift and append the function selector for approve(address,uint256)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            callStatus := call(gas(), token, 0, freeMemoryPointer, callDataLength, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}
