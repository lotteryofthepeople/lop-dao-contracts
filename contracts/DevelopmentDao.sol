// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";
import "./interfaces/IShareHolderDao.sol";
import "./interfaces/IProductDao.sol";
import "./libs/types.sol";

contract DevelopmentDao is GroupDao {
    using Counters for Counters.Counter;
    // proposal index
    Counters.Counter public proposalIndex;

    // product dao address
    address public productDao;

    // minimum vote number
    uint256 public minVote;

    // proposal id => DevelopmentProposal
    mapping(uint256 => Types.DevelopmentProposal) public proposals;
    // proposal owner => proposal status
    mapping(address => Types.ProposalStatus) public proposalStatus;
    // user address => proposal id => status
    mapping(address => mapping(uint256 => bool)) public isVoted;

    /**
     * @param creator proposal creator
     * @param proposalIndex proposal index
     * @param metadata metadata URL
     * @param _productId product id
     **/
    event ProposalCreated(
        address indexed creator,
        uint256 proposalIndex,
        string metadata,
        uint256 _productId
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
     * @param prev previous product address
     * @param next next product address
     * @dev emitted when dupdate product dao address by only owner
     **/
    event ProductDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param _shareHolderDao share holder dao address
     * @param _productDao product dao address
     * @param _minVote min vote number
     **/
    constructor(
        address _shareHolderDao,
        address _productDao,
        uint256 _minVote
    ) GroupDao(_shareHolderDao) {
        require(
            _productDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );
        require(
            _minVote > 0,
            "DevelopmentDao: min vote should be greater than the zero"
        );

        productDao = _productDao;
        minVote = _minVote;

        emit MinVoteUpdated(minVote);
        emit ProductDaoUpdated(address(0), productDao);
    }

    /**
     * @param _metadata metadata URL
     * @param _productId proposal id
     * @param _budget proposal budget
     **/
    function createProposal(
        string calldata _metadata,
        uint256 _productId,
        uint256 _budget
    ) external checkTokenHolder {
        require(
            bytes(_metadata).length > 0,
            "DevelopmentDao: metadata should not be empty string"
        );
        require(
            proposalStatus[msg.sender] == Types.ProposalStatus.NONE,
            "DevelopmentDao: You already created a new proposal"
        );
        Types.ProductProposal memory _prposal = IProductDao(productDao)
            .getProposalById(_productId);
        require(
            _prposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: proposal is not active now"
        );

        uint256 _proposalIndex = proposalIndex.current();

        Types.DevelopmentProposal memory _proposal = Types.DevelopmentProposal({
            metadata: _metadata,
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            voteYes: 0,
            voteNo: 0,
            productId: _productId,
            budget: _budget
        });

        proposals[_proposalIndex] = _proposal;
        proposalStatus[msg.sender] = Types.ProposalStatus.CREATED;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _proposalIndex, _metadata, _productId);
    }

    /**
     * @param _proposalId proposal id
     **/
    function voteYes(uint256 _proposalId) external checkTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];

        require(
            !isVoted[msg.sender][_proposalId],
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: proposal is not created status"
        );

        _proposal.voteYes++;

        emit VoteYes(_proposalId, msg.sender);
    }

    /**
     * @param _proposalId proposal id
     **/
    function voteNo(uint256 _proposalId) external checkTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];

        require(
            !isVoted[msg.sender][_proposalId],
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: proposal is not created status"
        );

        _proposal.voteNo++;

        emit VoteNo(_proposalId, msg.sender);
    }

    /**
     * @param _proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 _proposalId) external checkTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "DevelopmentDao: You are not the owner of this proposal"
        );

        Types.ShareHolderInfo memory _shareHolderInfo = IShareHolderDao(
            shareHolderDao
        ).getShareHolderInfoByUser(msg.sender);

        require(
            _proposal.budget < _shareHolderInfo.budget,
            "DevelopmentDao: proposal budget should be less than shareholder budget"
        );

        if (_proposal.voteYes >= minVote) {
            _proposal.status = Types.ProposalStatus.ACTIVE;
            emit Activated(_proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;
            emit Cancelled(_proposalId, msg.sender);
        }
    }

    /**
     * @param _minVote min vote number
     **/
    function setMinVote(uint256 _minVote) external onlyOwner {
        require(
            _minVote > 0,
            "DevelopmentDao: minVote should be greater than the zero"
        );

        minVote = _minVote;

        emit MinVoteUpdated(minVote);
    }
}
