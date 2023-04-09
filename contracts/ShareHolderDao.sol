// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/types.sol";

contract ShareHolderDao is Ownable {
    using Counters for Counters.Counter;

    // proposal index
    Counters.Counter public proposalIndex;

    // ERC20 LOP address
    address public LOP;
    // ERC20 vLOP address
    address public vLOP;
    // minimum vote number
    uint256 public minVote;

    // proposal id => ShareHolderProposal
    mapping(uint256 => Types.ShareHolderProposal) public proposals;
    // user => bool status
    mapping(address => bool) public isProposal;
    // user address => proposal id => status
    mapping(address => mapping(uint256 => bool)) public isVoted;

    /**
     * @param _LOP ERC20 LOP address
     **/
    event SetLOP(address indexed _LOP);

    /**
     * @param _vLOP ERC20 vLOP address
     **/
    event SetVLOP(address indexed _vLOP);

    /**
     * @param owner proposal owner
     * @param budget proposal budget
     * @param proposalId proposal id
     * @dev emitted when create a new proposal
     **/
    event ProposalCreated(
        address indexed owner,
        uint256 budget,
        uint256 proposalId
    );

    /**
     * @param voter voter
     * @param proposalId proposal id
     **/
    event VoteYes(address indexed voter, uint256 proposalId);

    /**
     * @param voter voter
     * @param proposalId proposal id
     **/
    event VoteNo(address indexed voter, uint256 proposalId);

    /**
     * @param proposalId propoal id
     **/
    event Activated(uint256 proposalId);

    /**
     * @param proposalId proposal id
     **/
    event Cancelled(uint256 proposalId);

    modifier checkTokenHolder() {
        require(
            IERC20(LOP).balanceOf(msg.sender) > 0 ||
                IERC20(vLOP).balanceOf(msg.sender) > 0,
            "ShareHolderDao: You have not enough token for LOP or vLOP"
        );
        _;
    }

    constructor(address _LOP, address _vLOP) {
        require(
            _LOP != address(0),
            "ShareHolderDao: LOP address hould not be the zero address"
        );
        require(
            _vLOP != address(0),
            "ShareHolderDao: vLOP address hould not be the zero address"
        );

        LOP = _LOP;
        vLOP = _vLOP;

        emit SetLOP(_LOP);
        emit SetVLOP(_vLOP);
    }

    /**
     * @param _LOP ERC20 LOP address
     * @dev only owner can set LOP address
     **/
    function setLOP(address _LOP) external onlyOwner {
        require(
            _LOP != address(0),
            "ShareHolderDao: LOP address hould not be the zero address"
        );

        LOP = _LOP;

        emit SetLOP(_LOP);
    }

    /**
     * @param _vLOP ERC20 vLOP address
     * @dev only owner can set vLOP address
     **/
    function setVLOP(address _vLOP) external onlyOwner {
        require(
            _vLOP != address(0),
            "ShareHolderDao: vLOP address hould not be the zero address"
        );

        vLOP = _vLOP;

        emit SetLOP(_vLOP);
    }

    /**
     * @param _budget proposal budget
     * @dev create a new proposal
     **/
    function createProposal(uint256 _budget) external checkTokenHolder {
        require(
            !isProposal[msg.sender],
            "ShareHolderDao: Your proposal is active now"
        );
        require(
            _budget > 0,
            "ShareHolderDao: budget should be greater than the zero"
        );

        Types.ShareHolderProposal memory _proposal = Types.ShareHolderProposal({
            budget: _budget,
            owner: msg.sender,
            status: Types.ProposalStatus.CREATED,
            voteYes: 0,
            voteNo: 0
        });

        uint256 _proposalIndex = proposalIndex.current();

        proposals[_proposalIndex] = _proposal;

        isProposal[msg.sender] = true;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _budget, _proposalIndex);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteYes(uint256 proposalId) external checkTokenHolder {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal is not created"
        );
        require(
            !isVoted[msg.sender][proposalId],
            "ShareHolderDao: You already voted this proposal"
        );

        _proposal.voteYes++;
        isVoted[msg.sender][proposalId] = true;

        emit VoteYes(msg.sender, proposalId);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteNo(uint256 proposalId) external checkTokenHolder {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal is not created"
        );
        require(
            !isVoted[msg.sender][proposalId],
            "ShareHolderDao: You already voted this proposal"
        );

        _proposal.voteNo++;
        isVoted[msg.sender][proposalId] = true;

        emit VoteNo(msg.sender, proposalId);
    }

    /**
     * @param proposalId proposal id
     **/
    function execute(uint256 proposalId) external checkTokenHolder {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "ShareHolderDao: You are not the owner of this proposal"
        );

        if (_proposal.voteYes >= minVote) {
            _proposal.status = Types.ProposalStatus.ACTIVE;
            emit Activated(proposalId);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;
            emit Cancelled(proposalId);
        }
    }
}
