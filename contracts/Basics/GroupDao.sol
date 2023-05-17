// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IStaking.sol";
import "../libs/types.sol";

contract GroupDao is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // join request index
    Counters.Counter public joinRequestIndex;
    // member index
    Counters.Counter public memberIndex;

    // staking address
    address public stakingAddress;

    // user address => group member status
    mapping(address => Types.Member) public members;
    // join request id => join request
    mapping(uint256 => Types.JoinRequest) public joinRequests;

    /**
     * @param requestId join request id
     * @param creator the creator of join request
     **/
    event JoinRequest(uint256 requestId, address indexed creator);

    /**
     * @param _joinRequestIndex join request index
     * @param acceptor acceptor
     **/
    event AeeptedJoinRequest(
        uint256 _joinRequestIndex,
        address indexed acceptor
    );

    /**
     * @param _user user address
     * @param _status member status
     * @dev emitted when update member status by only owner
     **/
    event MemberStatusUpdated(
        address indexed _user,
        Types.MemberStatus _status
    );

    /**
     * @param prev previous staking address
     * @param next next staking address
     * @dev emitted when dupdate staking address by only owner
     **/
    event StakingAddressUpdated(address indexed prev, address indexed next);

    /**
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event WithdrawNative(address indexed toAddress, uint256 amount);

    /**
     * @param token token address
     * @param toAddress destination address
     * @param amount withdraw amount
     **/
    event Withdraw(
        address indexed token,
        address indexed toAddress,
        uint256 amount
    );

    /**
     * @param _user user address
     **/
    modifier checkMember(address _user) {
        require(isMember(_user), "GroupDao: Not member of group");
        _;
    }

    modifier checkTokenHolder() {
        require(
            IERC20(getLOP()).balanceOf(msg.sender) > 0 ||
                IERC20(getVLOP()).balanceOf(msg.sender) > 0,
            "GroupDao: You have not enough LOP or vLOP token"
        );
        _;
    }

    /**
     * @param _stakingAddress share holder dao address
     **/
    constructor(address _stakingAddress) {
        require(
            _stakingAddress != address(0),
            "GroupDao: staking address should not be the zero address"
        );

        stakingAddress = _stakingAddress;

        memberIndex.increment();

        emit StakingAddressUpdated(address(0), stakingAddress);
    }

    /**
     * @dev create a new request to join group
     **/
    function requestToJoin() external {
        require(
            members[msg.sender].status == Types.MemberStatus.NONE,
            "GroupDao: You already sent join request or a member of group"
        );

        Types.JoinRequest memory _joinRequest = Types.JoinRequest({
            status: Types.JoinRequestStatus.CREATED,
            owner: msg.sender
        });

        uint256 _joinRequestIndex = joinRequestIndex.current();
        joinRequests[_joinRequestIndex] = _joinRequest;

        Types.Member memory _member = Types.Member({
            owner: msg.sender,
            status: Types.MemberStatus.JOINNING,
            requestId: _joinRequestIndex
        });

        members[msg.sender] = _member;

        joinRequestIndex.increment();

        emit JoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _joinRequestIndex join request index
     * @dev accept join request
     **/
    function acceptJoinRequest(
        uint256 _joinRequestIndex
    ) external checkMember(msg.sender) {
        Types.JoinRequest storage _joinRequest = joinRequests[
            _joinRequestIndex
        ];

        Types.Member storage _member = members[_joinRequest.owner];

        require(
            _joinRequest.status == Types.JoinRequestStatus.CREATED,
            "GroupDao: the request is not created"
        );
        require(
            _member.status == Types.MemberStatus.JOINNING,
            "GroupDao: member status is not joinning"
        );

        _joinRequest.status = Types.JoinRequestStatus.PASSED;
        _member.status == Types.MemberStatus.JOINED;

        memberIndex.increment();

        emit AeeptedJoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _stakingAddress new staking address
     **/
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(
            _stakingAddress != address(0),
            "GroupDao: staking address should not be the zero address"
        );

        address _prevStakingAddress = stakingAddress;

        stakingAddress = _stakingAddress;

        emit StakingAddressUpdated(_prevStakingAddress, stakingAddress);
    }

    /**
     * @param _user user address
     * @param _status member status
     * @dev set member status by only owner
     * @dev contract owner can disable, enable, block user for group
     **/
    function setMemberStatus(
        address _user,
        Types.MemberStatus _status
    ) external onlyOwner {
        require(
            _user != address(0),
            "GroupDao: user should not be the zero address"
        );
        require(
            members[_user].status != _status,
            "GroupDao: same status error"
        );

        if (members[_user].status == Types.MemberStatus.JOINED) {
            memberIndex.decrement();
        }

        if (_status == Types.MemberStatus.JOINED) {
            memberIndex.increment();
        }

        members[_user].status = _status;

        emit MemberStatusUpdated(_user, _status);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function withdrawNative(
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            toAddress != address(0),
            "GroupDao: The zero address should not be the fee address"
        );

        require(amount > 0, "GroupDao: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "GroupDao: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "GroupDao: Withdraw failed");

        emit WithdrawNative(toAddress, balance);
    }

    /**
     * @param token token address
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    function withdraw(
        address token,
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "GroupDao: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "GroupDao: to address should not be the zero address"
        );
        require(amount > 0, "GroupDao: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "GroupDao: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }

    /**
     * @dev get LOP address from ShareHolderDao
     **/
    function getLOP() public view returns (address) {
        return IStaking(stakingAddress).getLOP();
    }

    /**
     * @dev get vLOP address from ShareHolderDao
     **/
    function getVLOP() public view returns (address) {
        return IStaking(stakingAddress).getVLOP();
    }

    function getMinVotePercent() public view returns (uint256) {
        return IStaking(stakingAddress).getMinVotePercent();
    }

    /**
     * @param _user user address
     * @dev check is the member of gruop
     **/
    function isMember(address _user) public view returns (bool) {
        return
            members[_user].status == Types.MemberStatus.JOINED ||
            owner() == _user;
    }
}
