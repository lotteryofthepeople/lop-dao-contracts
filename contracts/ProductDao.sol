// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IShareHolderDao.sol";
import "./libs/types.sol";

contract ProductDao is Ownable {
    using Counters for Counters.Counter;

    // join request index
    Counters.Counter public joinRequestIndex;
    // proposal index
    Counters.Counter public proposalIndex;

    // share holder dao address
    address public shareHolderDao;

    // minimum vote number
    uint256 public minVote;

    // user address => group member status
    mapping(address => Types.Member) public members;
    // join request id => join request
    mapping(uint256 => Types.JoinRequest) public joinRequests;
    // proposal id => Product proposal
    mapping(uint256 => Types.ProductProposal) public proposals;
    // proposal owner => proposal status
    mapping(address => Types.ProposalStatus) public proposalStatus;
    // user address => proposal id => status
    mapping(address => mapping(uint256 => bool)) public isVoted;

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
     * @param creator proposal creator
     * @param proposalIndex proposal index
     * @param metadata metadata URL
     **/
    event ProposalCreated(
        address indexed creator,
        uint256 proposalIndex,
        string metadata
    );

    /**
     * @param proposalId proposal id
     * @param voter voter
     **/
    event VoteYes(uint256 proposalId, address indexed voter);

    /**
     * @param proposalId proposal id
     * @param voter voter
     **/
    event VoteNo(uint256 proposalId, address indexed voter);

    /**
     * @param proposalId propoal id
     * @param activator activator
     **/
    event Activated(uint256 proposalId, address indexed activator);

    /**
     * @param proposalId proposal id
     * @param canceller canceller
     **/
    event Cancelled(uint256 proposalId, address indexed canceller);

    /**
     * @param _minVote min vote number
     **/
    event MinVoteUpdated(uint256 _minVote);

    /**
     * @param _user user address
     **/
    modifier checkMember(address _user) {
        require(
            isMember(_user),
            "Not member of group"
        );
        _;
    }

    modifier checkTokenHolder() {
        require(
            IERC20(getLOP()).balanceOf(msg.sender) > 0 ||
                IERC20(getVLOP()).balanceOf(msg.sender) > 0,
            "ProductDao: You have not enough LOP or vLOP token"
        );
        _;
    }

    /**
     * @param _shareHolderDao share holder dao address
     * @param _minVote min vote number
     **/
    constructor(address _shareHolderDao, uint256 _minVote) {
        require(
            _shareHolderDao != address(0),
            "ProductDao: share holder dao address should not be the zero address"
        );
        require(
            _minVote > 0,
            "ProductDao: min vote should be greater than the zero"
        );

        shareHolderDao = _shareHolderDao;
        minVote = _minVote;

        emit ShareHolderDaoUpdated(address(0), shareHolderDao);
        emit MinVoteUpdated(minVote);
    }

    /**
     * @dev create a new request to join product group
     **/
    function requestToJoin() external {
        require(
            members[msg.sender].status == Types.MemberStatus.NONE,
            "ProductDao: You already sent join request or a member of product group"
        );

        Types.JoinRequest memory _joinRequest = Types
            .JoinRequest({
                status: Types.JoinRequestStatus.CREATED,
                owner: msg.sender
            });

        uint256 _joinRequestIndex = joinRequestIndex.current();
        joinRequests[_joinRequestIndex] = _joinRequest;

        Types.Member memory _productMember = Types.Member({
            owner: msg.sender,
            status: Types.MemberStatus.JOINNING,
            requestId: _joinRequestIndex
        });

        members[msg.sender] = _productMember;

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

        Types.Member storage _productMember = members[
            _joinRequest.owner
        ];

        require(
            _joinRequest.status == Types.JoinRequestStatus.CREATED,
            "ProductDao: the request is not created"
        );
        require(
            _productMember.status == Types.MemberStatus.JOINNING,
            "ProductDao: product member status is not joinning"
        );

        _joinRequest.status = Types.JoinRequestStatus.PASSED;
        _productMember.status == Types.MemberStatus.JOINED;

        emit AeeptedJoinRequest(_joinRequestIndex, msg.sender);
    }

    /**
     * @param _metadata metadata URL
     **/
    function createProposal(
        string calldata _metadata
    ) external checkTokenHolder {
        require(
            bytes(_metadata).length > 0,
            "ProdcutDao: metadata should not be empty string"
        );
        require(
            proposalStatus[msg.sender] == Types.ProposalStatus.NONE,
            "ProductDao: You already created a new proposal"
        );

        uint256 _proposalIndex = proposalIndex.current();

        Types.ProductProposal memory _proposal = Types.ProductProposal({
            metadata: _metadata,
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            voteYes: 0,
            voteNo: 0
        });

        proposals[_proposalIndex] = _proposal;
        proposalStatus[msg.sender] = Types.ProposalStatus.CREATED;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _proposalIndex, _metadata);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteYes(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = proposals[proposalId];

        require(
            !isVoted[msg.sender][proposalId],
            "ProductDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );

        _proposal.voteYes++;

        emit VoteYes(proposalId, msg.sender);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteNo(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = proposals[proposalId];

        require(
            !isVoted[msg.sender][proposalId],
            "ProductDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );

        _proposal.voteNo++;

        emit VoteNo(proposalId, msg.sender);
    }

    /**
     * @param proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = proposals[proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "ShareHolderDao: You are not the owner of this proposal"
        );

        if (_proposal.voteYes >= minVote) {
            _proposal.status = Types.ProposalStatus.ACTIVE;
            emit Activated(proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;
            emit Cancelled(proposalId, msg.sender);
        }
    }

    /**
     * @param _shareHolderDao new shoare holder dao address
     **/
    function setShareHolderDao(address _shareHolderDao) external onlyOwner {
        require(
            _shareHolderDao != address(0),
            "ProductDao: share holder dao address should not be the zero address"
        );

        address _prevShareHolderDao = shareHolderDao;

        shareHolderDao = _shareHolderDao;

        emit ShareHolderDaoUpdated(_prevShareHolderDao, _shareHolderDao);
    }

    /**
     * @param _user user address
     * @param _status product member status
     * @dev set member status by only owner
     * @dev contract owner can disable, enable, block user for product group
     **/
    function setMemberStatus(
        address _user,
        Types.MemberStatus _status
    ) external onlyOwner {
        require(
            _user != address(0),
            "ProductDao: user should not be the zero address"
        );

        members[_user].status = _status;

        emit MemberStatusUpdated(_user, _status);
    }


    /**
     * @param _minVote min vote number
     **/
    function setMinVote(uint256 _minVote) external onlyOwner {
        require(
            _minVote > 0,
            "ProdcutDao: minVote should be greater than the zero"
        );

        minVote = _minVote;

        emit MinVoteUpdated(minVote);
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
     * @dev check is the member of product gruop
     **/
    function isMember(address _user) public view returns (bool) {
        return
            members[_user].status == Types.MemberStatus.JOINED ||
            owner() == _user;
    }
}
