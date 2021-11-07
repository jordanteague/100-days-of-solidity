// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation with COMP-style governance,
/// @author Adapted from RariCapital, https://github.com/Rari-Capital/solmate/blob/main/src/erc20/ERC20.sol,
/// License-Identifier: AGPL-3.0-only.
contract VoteToken {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    event TransferDAO(address indexed from, address indexed to);

    event TogglePause(bool indexed paused);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                              DAO STORAGE
    //////////////////////////////////////////////////////////////*/

    address public dao;

    bool public paused;

    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) public delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint256 fromTimestamp;
        uint256 votes;
    }

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        address dao_,
        bool paused_,
        address[] memory voters,
        uint256[] memory shares
    ) {
        require(voters.length == shares.length, "NO_ARRAY_PARITY");

        name = name_;
        symbol = symbol_;
        dao = dao_;
        paused = paused_;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

        for (uint256 i; i < voters.length; i++) {
            _mint(voters[i], shares[i]);

            _delegate(voters[i], voters[i]);
        }

        emit TransferDAO(address(0), dao_);
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external notPaused returns (bool) {
        balanceOf[msg.sender] -= amount;

        // This is safe because the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external notPaused returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // This is safe because the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              DAO LOGIC
    //////////////////////////////////////////////////////////////*/

    modifier onlyDAO() {
        require(msg.sender == dao, "NOT_DAO");
        _;
    }

    modifier notPaused() {
        require(!paused, "PAUSED");
        _;
    }

    function getCurrentVotes(address account) external view returns (uint256 votes) {
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            votes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));

        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "ZERO_ADDRESS");

        unchecked {
            require(nonce == nonces[signatory]++, "INVALID_NONCE");
        }

        require(block.timestamp <= expiry, "SIGNATURE_EXPIRED");

        _delegate(signatory, delegatee);
    }

    function getPriorVotes(address account, uint256 timestamp) external view returns (uint256 votes) {
        require(timestamp < block.timestamp, "NOT_YET_DETERMINED");

        uint256 nCheckpoints = numCheckpoints[account];

        if (nCheckpoints == 0) {
            return 0;
        }

        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp) {
                return checkpoints[account][nCheckpoints - 1].votes;
            }

            if (checkpoints[account][0].fromTimestamp > timestamp) {
                return 0;
            }

            uint256 lower;

            uint256 upper = nCheckpoints - 1;

            while (upper > lower) {
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

        return checkpoints[account][lower].votes;

        }
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];

        delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        unchecked {
            if (srcRep != dstRep && amount > 0) {
                if (srcRep != address(0)) {
                    uint256 srcRepNum = numCheckpoints[srcRep];

                    uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                    uint256 srcRepNew = srcRepOld - amount;

                    _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
                }

                if (dstRep != address(0)) {
                    uint256 dstRepNum = numCheckpoints[dstRep];

                    uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

                    uint256 dstRepNew = dstRepOld + amount;

                    _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
                }
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        unchecked {
            if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(block.timestamp, newVotes);

                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function _computeDomainSeparator() internal view returns (bytes32 domainSeparator) {
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        domainSeparator = block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // This is reasonably safe from overflow because incrementing `nonces` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /*///////////////////////////////////////////////////////////////
                           MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external onlyDAO {
        _mint(to, amount);

        _moveDelegates(address(0), delegates[to], amount);
    }

    function burn(address from, uint256 amount) external onlyDAO {
        _burn(from, amount);

        _moveDelegates(delegates[from], address(0), amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;

        // This is safe because the sum of all user
        // balances can't exceed 'type(uint256).max'.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;

        // This is safe because a user won't ever
        // have a balance larger than `totalSupply`.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }

    /*///////////////////////////////////////////////////////////////
                           PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function togglePause() external onlyDAO {
        paused = !paused;

        emit TogglePause(paused);
    }
}