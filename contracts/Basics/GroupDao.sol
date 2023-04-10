// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IShareHolderDao.sol";
import "../libs/types.sol";

contract GroupDao is Ownable {
    using Counters for Counters.Counter;

    // join request index
    Counters.Counter public joinRequestIndex;

    // share holder dao address
    address public shareHolderDao;

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
     * @param prev previous shareholder address
     * @param next next shareholder address
     * @dev emitted when dupdate share holder dao address by only owner
     **/
    event ShareHolderDaoUpdated(address indexed prev, address indexed next);

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
     * @param _shareHolderDao share holder dao address
     **/
    constructor(address _shareHolderDao) {
        require(
            _shareHolderDao != address(0),
            "GroupDao: share holder dao address should not be the zero address"
        );

        shareHolderDao = _shareHolderDao;

        emit ShareHolderDaoUpdated(address(0), shareHolderDao);
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

        emit AeeptedJoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _shareHolderDao new shoare holder dao address
     **/
    function setShareHolderDao(address _shareHolderDao) external onlyOwner {
        require(
            _shareHolderDao != address(0),
            "GroupDao: share holder dao address should not be the zero address"
        );

        address _prevShareHolderDao = shareHolderDao;

        shareHolderDao = _shareHolderDao;

        emit ShareHolderDaoUpdated(_prevShareHolderDao, _shareHolderDao);
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

        members[_user].status = _status;

        emit MemberStatusUpdated(_user, _status);
    }

    /**
     * @dev get LOP address from ShareHolderDao
     **/
    function getLOP() public returns (address) {
        return IShareHolderDao(shareHolderDao).getLOP();
    }

    /**
     * @dev get vLOP address from ShareHolderDao
     **/
    function getVLOP() public returns (address) {
        return IShareHolderDao(shareHolderDao).getVLOP();
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