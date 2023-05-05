// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";
import "./interfaces/IProductDao.sol";
import "./interfaces/IERC20LOP.sol";

contract DevelopmentDao is GroupDao {
    using Counters for Counters.Counter;
    // proposal index
    Counters.Counter public proposalIndex;
    // escrow proposal index
    Counters.Counter public escrowProposalIndex;

    // product dao address
    address public productDao;

    // proposal id => DevelopmentProposal
    mapping(uint256 => Types.DevelopmentProposal) public proposals;
    // proposal owner => proposal status
    mapping(address => Types.ProposalStatus) public proposalStatus;
    // user address => proposal id => status
    mapping(address => mapping(uint256 => bool)) public isVoted;
    // proposal id => escrow amount
    mapping(uint256 => uint256) public escrow;
    // escrow proposal id => escrow proposal
    mapping(uint256 => Types.EscrowProposal) public escrowProposals;
    // user address => escrow proposal id => status
    mapping(address => mapping(uint256 => bool)) public escrowIsVoted;

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
        uint256 _productId,
        uint256 budget
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
     * @param proposalId propoal id
     * @param activator activator
     **/
    event EscrowActivated(uint256 proposalId, address indexed activator);

    /**
     * @param proposalId proposal id
     * @param canceller canceller
     **/
    event EscrowCancelled(uint256 proposalId, address indexed canceller);

    /**
     * @param prev previous product address
     * @param next next product address
     * @dev emitted when dupdate product dao address by only owner
     **/
    event ProductDaoUpdated(address indexed prev, address indexed next);

    /**
     * @param proposalId proposal id
     * @param amount escrow amount
     * @param escrowProposalIndex escrow proposal index
     **/
    event EscrowProposalCreated(
        uint256 proposalId,
        uint256 amount,
        uint256 escrowProposalIndex
    );

    /**
     * @param escrowId escrow proposal id
     * @param voter voter address
     **/
    event EscrowVoteYes(uint256 escrowId, address indexed voter);

    /**
     * @param escrowId escrow proposal id
     * @param voter voter address
     **/
    event EscrowVoteNo(uint256 escrowId, address indexed voter);

    /**
     * @param _shareHolderDao share holder dao address
     * @param _productDao product dao address
     **/
    constructor(
        address _shareHolderDao,
        address _productDao
    ) GroupDao(_shareHolderDao) {
        require(
            _productDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );

        productDao = _productDao;

        memberIndex.current();

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

        emit ProposalCreated(
            msg.sender,
            _proposalIndex,
            _metadata,
            _productId,
            _budget
        );
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
        isVoted[msg.sender][_proposalId] = true;

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
        isVoted[msg.sender][_proposalId] = true;

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
            _proposal.budget <= _shareHolderInfo.budget,
            "DevelopmentDao: proposal budget should be less than shareholder budget"
        );

        uint256 _voteYesPercent = (_proposal.voteYes * 100) /
            memberIndex.current();

        proposalStatus[msg.sender] = Types.ProposalStatus.NONE;

        if (
            _voteYesPercent >=
            IShareHolderDao(shareHolderDao).getMinVotePercent()
        ) {
            _proposal.status = Types.ProposalStatus.ACTIVE;

            IShareHolderDao(shareHolderDao).decreaseBudget(_proposal.budget);

            IERC20LOP(getLOP()).mint(address(this), _proposal.budget);

            escrow[_proposalId] = _proposal.budget;

            emit Activated(_proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;

            emit Cancelled(_proposalId, msg.sender);
        }
    }

    /**
     * @param _proposalId proposal id
     **/
    function escrowCreateProposal(
        uint256 _proposalId,
        uint256 _amount
    ) external checkTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];

        require(
            _proposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: Proposal status is not activated"
        );
        require(
            _proposal.owner == msg.sender,
            "DevelopmentDao: You are not the owner of proposal"
        );
        require(
            _amount > 0,
            "DevelopmentDao: amount should be greater than the zero"
        );
        require(
            escrow[_proposalId] >= _amount,
            "DevelopmentDao: amount should be less than the escrow budget"
        );

        Types.EscrowProposal memory _escrowProposal = Types.EscrowProposal({
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            budget: _amount,
            voteYes: 0,
            voteNo: 0
        });

        uint256 _escrowProposalIndex = escrowProposalIndex.current();
        escrowProposals[_escrowProposalIndex] = _escrowProposal;

        escrowProposalIndex.increment();

        emit EscrowProposalCreated(_proposalId, _amount, _escrowProposalIndex);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteYes(uint256 escrowId) external checkTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowIsVoted[msg.sender][escrowId],
            "DevelopmentDao: You already voted this proposal"
        );

        escrowIsVoted[msg.sender][escrowId] = true;

        _escrowProposal.voteYes += 1;

        emit EscrowVoteYes(escrowId, msg.sender);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteNo(uint256 escrowId) external checkTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowIsVoted[msg.sender][escrowId],
            "DevelopmentDao: You already voted this proposal"
        );

        escrowIsVoted[msg.sender][escrowId] = true;

        _escrowProposal.voteNo += 1;

        emit EscrowVoteNo(escrowId, msg.sender);
    }

    function escrowVoteExecute(uint256 escrowId) external checkTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            _escrowProposal.owner == msg.sender,
            "DevelopmentDao: only proposal owner can execute"
        );

        uint256 _voteYesPercent = (_escrowProposal.voteYes * 100) /
            memberIndex.current();

        if (
            _voteYesPercent >=
            IShareHolderDao(shareHolderDao).getMinVotePercent()
        ) {
            _escrowProposal.status = Types.ProposalStatus.ACTIVE;

            escrow[escrowId] -= _escrowProposal.budget;

            require(
                IERC20LOP(IShareHolderDao(shareHolderDao).getLOP()).transfer(
                    msg.sender,
                    _escrowProposal.budget
                ),
                "DevelopmentDao: tansfer LOP token fail"
            );

            emit EscrowActivated(escrowId, msg.sender);
        } else {
            _escrowProposal.status = Types.ProposalStatus.CANCELLED;

            emit EscrowCancelled(escrowId, msg.sender);
        }
    }
}
