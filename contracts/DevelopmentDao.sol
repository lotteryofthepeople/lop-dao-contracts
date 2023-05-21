// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Basics/GroupDao.sol";
import "./interfaces/IProductDao.sol";
import "./interfaces/IERC20LOP.sol";
import "./interfaces/IShareHolderDao.sol";

contract DevelopmentDao is GroupDao {
    using Counters for Counters.Counter;
    // proposal index
    Counters.Counter public proposalIndex;
    // escrow proposal index
    Counters.Counter public escrowProposalIndex;

    // product dao address
    address public productDao;
    // share holder dao address
    address public shareHolderDao;

    // proposal id => DevelopmentProposal
    mapping(uint256 => Types.DevelopmentProposal) public proposals;
    // user address => proposal id => voting info
    mapping(address => mapping(uint256 => Types.VotingInfo)) public votingList;
    // proposal id => escrow amount
    mapping(uint256 => uint256) public escrowBudgets;
    // escrow proposal id => escrow proposal
    mapping(uint256 => Types.EscrowProposal) public escrowProposals;
    // user address => escrow proposal id => status
    mapping(address => mapping(uint256 => Types.VotingInfo))
        public escrowVotingList;

    /**
     * @param creator proposal creator
     * @param proposalIndex proposal index
     * @param metadata metadata URL
     * @param productId product id
     * @param budget budget
     **/
    event ProposalCreated(
        address indexed creator,
        uint256 proposalIndex,
        string metadata,
        uint256 productId,
        uint256 budget
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
    event ShareHolderDaoUpdated(address indexed prev, address indexed next);

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
     * @param voter voter address
     * @param escrowId escrow proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event EscrowVoteYes(
        address indexed voter,
        uint256 escrowId,
        uint256 tokenAmount
    );

    /**
     * @param voter voter address
     * @param escrowId escrow proposal id
     * @param tokenAmount LOP + vLOP token amount when vote
     **/
    event EscrowVoteNo(
        address indexed voter,
        uint256 escrowId,
        uint256 tokenAmount
    );

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
     * @param staker address staker
     * @param escrowProposalId proposal id
     * @param oldAmount old amount
     * @param newAmount new amount
     **/
    event EvaluateEscrowVoteAmount(
        address indexed staker,
        uint256 escrowProposalId,
        uint256 oldAmount,
        uint256 newAmount
    );

    /**
     * @param _shareHolderDao share holder dao address
     * @param _productDao product dao address
     **/
    constructor(
        address _shareHolderDao,
        address _productDao,
        address _stakingAddress
    ) GroupDao(_stakingAddress) {
        require(
            _shareHolderDao != address(0),
            "DevelopmentDao: share holder dao address should not be the zero address"
        );
        require(
            _productDao != address(0),
            "DevelopmentDao: product dao address should not be the zero address"
        );

        shareHolderDao = _shareHolderDao;

        productDao = _productDao;

        memberIndex.increment();

        emit ShareHolderDaoUpdated(address(0), shareHolderDao);
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
    ) external onlyTokenHolder {
        Types.ProductProposal memory _prposal = IProductDao(productDao)
            .getProposalById(_productId);

        require(
            bytes(_metadata).length > 0,
            "DevelopmentDao: metadata should not be empty string"
        );
        require(
            _prposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: proposal is not active now"
        );
        require(
            _budget > 0,
            "DevelopmentDao: budget should be greater than the zero"
        );

        uint256 _proposalIndex = proposalIndex.current();

        Types.DevelopmentProposal memory _proposal = Types.DevelopmentProposal({
            metadata: _metadata,
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            productId: _productId,
            budget: _budget,
            createdAt: block.timestamp
        });

        proposals[_proposalIndex] = _proposal;

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
    function voteYes(uint256 _proposalId) external onlyStaker {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            _proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _stakeInfo.developmentVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteYes++;
        _proposal.voteYesAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = true;

        IStaking(stakingAddress).addDevelopmentVotingId(
            msg.sender,
            _proposalId
        );

        emit VoteYes(msg.sender, _proposalId, _tokenAmount);
    }

    /**
     * @param _proposalId proposal id
     **/
    function voteNo(uint256 _proposalId) external onlyStaker {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            _proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "DevelopmentDao: proposal is already voted"
        );
        require(
            _stakeInfo.developmentVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteNo++;
        _proposal.voteNoAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = false;

        IStaking(stakingAddress).addDevelopmentVotingId(
            msg.sender,
            _proposalId
        );

        emit VoteNo(msg.sender, _proposalId, _tokenAmount);
    }

    /**
     * @param _proposalId proposal id
     * @dev only proposal creator can execute one's proposal
     **/
    function execute(uint256 _proposalId) external onlyTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "DevelopmentDao: You are not the owner of this proposal"
        );

        uint256 _shareHolderTotalBudget = IShareHolderDao(shareHolderDao)
            .totalBudget();

        require(
            _proposal.budget <= _shareHolderTotalBudget,
            "DevelopmentDao: proposal budget should be less than shareholder budget"
        );

        uint256 _voteYesPercent = (_proposal.voteYesAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        uint256 _totalYesPercent = (_proposal.voteYesAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        uint256 _totalNoPercent = (_proposal.voteNoAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        if (!(_totalYesPercent > 50 || _totalNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _proposal.createdAt) >= block.timestamp,
                "DevelopmentDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= IStaking(stakingAddress).getMinVotePercent()) {
            _proposal.status = Types.ProposalStatus.ACTIVE;

            IShareHolderDao(shareHolderDao).decreaseBudget(_proposal.budget);

            IERC20LOP(getLOP()).mint(address(this), _proposal.budget);

            escrowBudgets[_proposalId] = _proposal.budget;

            IStaking(stakingAddress).removeDevelopmentVotingId(
                msg.sender,
                _proposalId
            );

            emit Activated(_proposalId, msg.sender);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;

            IStaking(stakingAddress).removeDevelopmentVotingId(
                msg.sender,
                _proposalId
            );

            emit Cancelled(_proposalId, msg.sender);
        }
    }

    /**
     * @param _proposalId proposal id
     * @param _amount proposal amount
     **/
    function escrowCreateProposal(
        uint256 _proposalId,
        uint256 _amount
    ) external onlyTokenHolder {
        Types.DevelopmentProposal storage _proposal = proposals[_proposalId];

        require(
            _proposal.status == Types.ProposalStatus.ACTIVE,
            "DevelopmentDao: Proposal status is not active"
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
            escrowBudgets[_proposalId] >= _amount,
            "DevelopmentDao: amount should be less than the escrow budget"
        );

        Types.EscrowProposal memory _escrowProposal = Types.EscrowProposal({
            status: Types.ProposalStatus.CREATED,
            owner: msg.sender,
            budget: _amount,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            createdAt: block.timestamp
        });

        uint256 _escrowProposalIndex = escrowProposalIndex.current();
        escrowProposals[_escrowProposalIndex] = _escrowProposal;

        escrowProposalIndex.increment();

        emit EscrowProposalCreated(_proposalId, _amount, _escrowProposalIndex);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteYes(uint256 escrowId) external onlyTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowVotingList[msg.sender][escrowId].isVoted,
            "DevelopmentDao: You already voted this proposal"
        );
        require(
            _stakeInfo.developmentEscrowVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        escrowVotingList[msg.sender][escrowId].isVoted = true;
        escrowVotingList[msg.sender][escrowId].voteAmount = _tokenAmount;
        escrowVotingList[msg.sender][escrowId].voteType = true;

        _escrowProposal.voteYes += 1;
        _escrowProposal.voteYesAmount += _tokenAmount;

        IStaking(stakingAddress).addDevelopmentEscrowVotingId(
            msg.sender,
            escrowId
        );

        emit EscrowVoteYes(msg.sender, escrowId, _tokenAmount);
    }

    /**
     * @param escrowId escrow proposal id
     **/
    function escrowVoteNo(uint256 escrowId) external onlyTokenHolder {
        Types.EscrowProposal storage _escrowProposal = escrowProposals[
            escrowId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _escrowProposal.status == Types.ProposalStatus.CREATED,
            "DevelopmentDao: escrow proposal is not created"
        );
        require(
            !escrowVotingList[msg.sender][escrowId].isVoted,
            "DevelopmentDao: You already voted this proposal"
        );
        require(
            _stakeInfo.developmentEscrowVotingIds.length <
                IStaking(stakingAddress).MAX_DEVELOPMENT_VOTING_COUNT(),
            "DevelopmentDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        escrowVotingList[msg.sender][escrowId].isVoted = true;
        escrowVotingList[msg.sender][escrowId].voteAmount = _tokenAmount;
        escrowVotingList[msg.sender][escrowId].voteType = false;

        _escrowProposal.voteNo += 1;
        _escrowProposal.voteNoAmount += _tokenAmount;

        IStaking(stakingAddress).addDevelopmentEscrowVotingId(
            msg.sender,
            escrowId
        );

        emit EscrowVoteNo(msg.sender, escrowId, _tokenAmount);
    }

    function escrowVoteExecute(uint256 escrowId) external onlyTokenHolder {
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

        uint256 _voteYesPercent = (_escrowProposal.voteYesAmount * 100) /
            (_escrowProposal.voteYesAmount + _escrowProposal.voteNoAmount);

        uint256 _totalYesPercent = (_escrowProposal.voteYesAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        uint256 _totalNoPercent = (_escrowProposal.voteNoAmount * 100) /
            (IERC20(IStaking(stakingAddress).getVLOP()).totalSupply() +
                IERC20(IStaking(stakingAddress).getLOP()).totalSupply());

        if (!(_totalYesPercent > 50 || _totalNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _escrowProposal.createdAt) >= block.timestamp,
                "DevelopmentDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= IStaking(stakingAddress).getMinVotePercent()) {
            _escrowProposal.status = Types.ProposalStatus.ACTIVE;

            escrowBudgets[escrowId] -= _escrowProposal.budget;

            require(
                IERC20LOP(IStaking(stakingAddress).getLOP()).transfer(
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

    function evaluateVoteAmount(
        address staker,
        uint256 proposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "DevelopmentDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _votingInfo = votingList[staker][proposalId];
        Types.DevelopmentProposal storage _developmentProposal = proposals[
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);

        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _votingInfo.voteAmount;

        if (_votingInfo.isVoted) {
            if (_votingInfo.voteType) {
                // vote yes
                _developmentProposal.voteYesAmount =
                    _developmentProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _developmentProposal.voteNoAmount =
                    _developmentProposal.voteNoAmount +
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

    function evaluateEscrowVoteAmount(
        address staker,
        uint256 escrowProposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "DevelopmentDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _escrowVotingInfo = escrowVotingList[staker][
            escrowProposalId
        ];
        Types.EscrowProposal
            storage _developmentEscrowProposal = escrowProposals[
                escrowProposalId
            ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);

        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _escrowVotingInfo.voteAmount;

        if (_escrowVotingInfo.isVoted) {
            if (_escrowVotingInfo.voteType) {
                // vote yes
                _developmentEscrowProposal.voteYesAmount =
                    _developmentEscrowProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _developmentEscrowProposal.voteNoAmount =
                    _developmentEscrowProposal.voteNoAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            }

            _escrowVotingInfo.voteAmount = _newStakeAmount;
        }

        emit EvaluateEscrowVoteAmount(
            staker,
            escrowProposalId,
            _oldStakeAmount,
            _newStakeAmount
        );
    }
}
