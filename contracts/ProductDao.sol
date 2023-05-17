// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";

contract ProductDao is GroupDao {
    using Counters for Counters.Counter;
    // proposal index
    Counters.Counter public proposalIndex;

    // proposal id => Product proposal
    mapping(uint256 => Types.ProductProposal) public _proposals;
    // proposal owner => proposal status
    mapping(address => Types.ProposalStatus) public proposalStatus;
    // user address => proposal id => status
    mapping(address => mapping(uint256 => bool)) public isVoted;

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
     * @param stakingAddress staking address
     **/
    event SetStakingAddress(uint256 stakingAddress);

    /**
     * @param _stakingAddress staking address
     **/
    constructor(address _stakingAddress) GroupDao(_stakingAddress) {
        memberIndex.current();
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

        _proposals[_proposalIndex] = _proposal;
        proposalStatus[msg.sender] = Types.ProposalStatus.CREATED;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _proposalIndex, _metadata);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteYes(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = _proposals[proposalId];

        require(
            !isVoted[msg.sender][proposalId],
            "ProductDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );

        _proposal.voteYes++;
        isVoted[msg.sender][proposalId] = true;

        emit VoteYes(proposalId, msg.sender);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteNo(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = _proposals[proposalId];

        require(
            !isVoted[msg.sender][proposalId],
            "ProductDao: proposal is already voted"
        );
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );

        _proposal.voteNo++;
        isVoted[msg.sender][proposalId] = true;

        emit VoteNo(proposalId, msg.sender);
    }

    /**
     * @param proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 proposalId) external checkTokenHolder {
        Types.ProductProposal storage _proposal = _proposals[proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "ProductDao: You are not the owner of this proposal"
        );

        uint256 _voteYesPercent = (_proposal.voteYes * 100) /
            memberIndex.current();

        proposalStatus[msg.sender] = Types.ProposalStatus.NONE;

        if (_voteYesPercent >= getMinVotePercent()) {
            _proposal.status = Types.ProposalStatus.ACTIVE;
            emit Activated(proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;
            emit Cancelled(proposalId, msg.sender);
        }
    }

    function getProposalById(
        uint256 _proposalId
    ) external view returns (Types.ProductProposal memory _proposal) {
        _proposal = _proposals[_proposalId];
    }
}
