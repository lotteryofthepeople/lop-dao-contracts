// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";

contract ProductDao is GroupDao {
    using Counters for Counters.Counter;

    // proposal id => Product proposal
    mapping(uint256 => Types.ProductProposal) private _proposals;

    // proposal index
    Counters.Counter public proposalIndex;

    // user address => proposal id => voting info
    mapping(address => mapping(uint256 => Types.VotingInfo)) public votingList;

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
     * @param voter voter
     * @param proposalId proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event VoteYes(
        address indexed voter,
        uint256 proposalId,
        uint256 tokenAmount
    );

    /**
     * @param voter voter
     * @param proposalId proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event VoteNo(
        address indexed voter,
        uint256 proposalId,
        uint256 tokenAmount
    );

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
     * @param staker address staker
     * @param proposalId proposal id
     * @param oldAmount old amount
     * @param newAmount new amount
     **/
    event EvaluateVoteAmount(
        address indexed staker,
        uint256 proposalId,
        uint256 oldAmount,
        uint256 newAmount
    );

    /**
     * @param _stakingAddress staking address
     **/
    constructor(address _stakingAddress) GroupDao(_stakingAddress) {
        memberIndex.increment();
    }

    /**
     * @param _metadata metadata URL
     **/
    function createProposal(
        string calldata _metadata
    ) external onlyTokenHolder {
        require(
            bytes(_metadata).length > 0,
            "ProdcutDao: metadata should not be empty string"
        );

        uint256 _proposalIndex = proposalIndex.current();

        Types.ProductProposal memory _proposal = Types.ProductProposal({
            metadata: _metadata,
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            createdAt: 0
        });

        _proposals[_proposalIndex] = _proposal;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _proposalIndex, _metadata);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteYes(uint256 proposalId) external onlyStaker {
        Types.ProductProposal storage _proposal = _proposals[proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(!_votingInfo.isVoted, "ProductDao: proposal is already voted");
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );
        require(
            _stakeInfo.productVotingIds.length <
                IStaking(stakingAddress).MAX_PRODUCT_VOTING_COUNT(),
            "ProductDao: Your voting count reach out max product voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteYes++;
        _proposal.voteYesAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = true;

        IStaking(stakingAddress).addProductVotingId(msg.sender, proposalId);

        emit VoteYes(msg.sender, proposalId, _tokenAmount);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteNo(uint256 proposalId) external onlyStaker {
        Types.ProductProposal storage _proposal = _proposals[proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(!_votingInfo.isVoted, "ProductDao: proposal is already voted");
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: proposal is not created status"
        );
        require(
            _stakeInfo.productVotingIds.length <
                IStaking(stakingAddress).MAX_PRODUCT_VOTING_COUNT(),
            "ProductDao: Your voting count reach out max product voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteNo++;
        _proposal.voteNoAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = true;

        IStaking(stakingAddress).addProductVotingId(msg.sender, proposalId);

        emit VoteNo(msg.sender, proposalId, _tokenAmount);
    }

    /**
     * @param proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 proposalId) external onlyTokenHolder {
        Types.ProductProposal storage _proposal = _proposals[proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ProductDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "ProductDao: You are not the owner of this proposal"
        );

        uint256 _voteYesPercent = (_proposal.voteYesAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        uint256 _voteNoPercent = (_proposal.voteNoAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        if (!(_voteYesPercent > 50 || _voteNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _proposal.createdAt) >= block.timestamp,
                "ProductDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= getMinVotePercent()) {
            _proposal.status = Types.ProposalStatus.ACTIVE;

            IStaking(stakingAddress).removeProductVotingId(
                msg.sender,
                proposalId
            );

            emit Activated(proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;

            IStaking(stakingAddress).removeProductVotingId(
                msg.sender,
                proposalId
            );

            emit Cancelled(proposalId, msg.sender);
        }
    }

    function evaluateVoteAmount(
        address staker,
        uint256 proposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "ProductDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _votingInfo = votingList[staker][proposalId];
        Types.ProductProposal storage _productProposal = _proposals[proposalId];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);

        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _votingInfo.voteAmount;

        if (_votingInfo.isVoted) {
            if (_votingInfo.voteType) {
                // vote yes
                _productProposal.voteYesAmount =
                    _productProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _productProposal.voteNoAmount =
                    _productProposal.voteNoAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            }

            _votingInfo.voteAmount = _newStakeAmount;
        }

        emit EvaluateVoteAmount(
            staker,
            proposalId,
            _oldStakeAmount,
            _newStakeAmount
        );
    }

    function getProposalById(
        uint256 _proposalId
    ) external view returns (Types.ProductProposal memory _proposal) {
        _proposal = _proposals[_proposalId];
    }
}
