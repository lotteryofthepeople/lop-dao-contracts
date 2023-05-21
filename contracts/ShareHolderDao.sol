// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/types.sol";
import "./interfaces/IStaking.sol";

contract ShareHolderDao is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // proposal index
    Counters.Counter public proposalIndex;
    // member index
    Counters.Counter public memberIndex;

    address public stakingAddress;

    address public developmentDaoAddress;

    uint256 public totalBudget;

    // proposal id => ShareHolderProposal
    mapping(uint256 => Types.ShareHolderProposal) public proposals;
    // user address => proposal id => voting info
    mapping(address => mapping(uint256 => Types.VotingInfo)) public votingList;
    // user address => member status
    mapping(address => bool) public isMember;

    /**
     * @param stakingAddress staking address
     **/
    event SetStakingAddress(address indexed stakingAddress);

    /**
     * @param developmentDaoAddress staking address
     **/
    event SetDevelopmentDaoAddress(address indexed developmentDaoAddress);

    /**
     * @param owner proposal owner
     * @param budget proposal budget
     * @param proposalId proposal id
     * @param metadata metadata
     * @dev emitted when create a new proposal
     **/
    event ProposalCreated(
        address indexed owner,
        uint256 budget,
        uint256 proposalId,
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
     **/
    event Activated(uint256 proposalId);

    /**
     * @param proposalId proposal id
     **/
    event Cancelled(uint256 proposalId);

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
     * @param owner address owner
     * @param amount decrease amount
     **/
    event BudgetDecreased(address owner, uint256 amount);

    modifier onlyTokenHolder() {
        require(
            IERC20(IStaking(stakingAddress).getLOP()).balanceOf(msg.sender) >
                0 ||
                IERC20(IStaking(stakingAddress).getVLOP()).balanceOf(
                    msg.sender
                ) >
                0,
            "ShareHolderDao: You have not enough LOP or vLOP token"
        );
        _;
    }

    modifier onlyStaker() {
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);
        require(
            (_stakeInfo.lopAmount + _stakeInfo.vLopAmount) > 0,
            "ShareHolderDao: You have to stake LOP or vLOP token to access this contract"
        );
        _;
    }

    modifier onlyStakingContract() {
        require(
            stakingAddress == msg.sender,
            "ShareHolderDao: Only staking contract can access this function"
        );
        _;
    }

    modifier onlyDevelopmentDaoContract() {
        require(
            developmentDaoAddress == msg.sender,
            "ShareHolderDao: Only development dao contract can access this function"
        );
        _;
    }

    constructor(address _stakingAddress) {
        require(
            _stakingAddress != address(0),
            "ShareHolderDao: staking address shoud not be the zero address"
        );

        stakingAddress = _stakingAddress;

        memberIndex.increment();
    }

    /**
     * @param _budget proposal budget
     * @dev create a new proposal
     **/
    function createProposal(
        uint256 _budget,
        string calldata metadata
    ) external onlyTokenHolder {
        require(
            _budget > 0,
            "ShareHolderDao: budget should be greater than the zero"
        );
        require(
            bytes(metadata).length > 0,
            "ShareHolderDao: metadata should not be empty"
        );

        Types.ShareHolderProposal memory _proposal = Types.ShareHolderProposal({
            budget: _budget,
            owner: msg.sender,
            status: Types.ProposalStatus.CREATED,
            voteYes: 0,
            voteYesAmount: 0,
            voteNo: 0,
            voteNoAmount: 0,
            createdAt: block.timestamp
        });

        uint256 _proposalIndex = proposalIndex.current();

        proposals[_proposalIndex] = _proposal;

        proposalIndex.increment();

        emit ProposalCreated(msg.sender, _budget, _proposalIndex, metadata);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteYes(uint256 proposalId) external onlyStaker {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "ShareHolderDao: You already voted this proposal"
        );
        require(
            _stakeInfo.shareHolderVotingIds.length <
                IStaking(stakingAddress).MAX_SHARE_HOLDER_VOTING_COUNT(),
            "ShareHolderDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteYes++;
        _proposal.voteYesAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = true;

        IStaking(stakingAddress).addShareHolderVotingId(msg.sender, proposalId);

        emit VoteYes(msg.sender, proposalId, _tokenAmount);
    }

    /**
     * @param proposalId proposal id
     **/
    function voteNo(uint256 proposalId) external onlyStaker {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];
        Types.VotingInfo storage _votingInfo = votingList[msg.sender][
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(msg.sender);

        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal is not created"
        );
        require(
            !_votingInfo.isVoted,
            "ShareHolderDao: You already voted this proposal"
        );
        require(
            _stakeInfo.shareHolderVotingIds.length <=
                IStaking(stakingAddress).MAX_SHARE_HOLDER_VOTING_COUNT(),
            "ShareHolderDao: Your voting count reach out max share holder voting count"
        );

        uint256 _tokenAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;

        _proposal.voteNo++;
        _proposal.voteNoAmount += _tokenAmount;

        _votingInfo.isVoted = true;
        _votingInfo.voteAmount = _tokenAmount;
        _votingInfo.voteType = false;

        IStaking(stakingAddress).addShareHolderVotingId(msg.sender, proposalId);

        emit VoteNo(msg.sender, proposalId, _tokenAmount);
    }

    /**
     * @param proposalId proposal id
     **/
    function execute(uint256 proposalId) external onlyTokenHolder {
        Types.ShareHolderProposal storage _proposal = proposals[proposalId];
        require(
            _proposal.status == Types.ProposalStatus.CREATED,
            "ShareHolderDao: Proposal status is not created"
        );
        require(
            _proposal.owner == msg.sender,
            "ShareHolderDao: You are not the owner of this proposal"
        );

        uint256 _voteYesPercent = (_proposal.voteYesAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        uint256 _voteNoPercent = (_proposal.voteNoAmount * 100) /
            (_proposal.voteYesAmount + _proposal.voteNoAmount);

        if (!(_voteYesPercent > 50 || _voteNoPercent > 50)) {
            require(
                (IStaking(stakingAddress).getProposalExpiredDate() +
                    _proposal.createdAt) >= block.timestamp,
                "ShareHolderDao: You can execute proposal after expired"
            );
        }

        if (_voteYesPercent >= IStaking(stakingAddress).getMinVotePercent()) {
            _proposal.status = Types.ProposalStatus.ACTIVE;

            totalBudget += _proposal.budget;

            if (!isMember[msg.sender]) {
                memberIndex.increment();
                isMember[msg.sender] = true;
            }

            IStaking(stakingAddress).removeShareHolderVotingId(
                msg.sender,
                proposalId
            );

            emit Activated(proposalId);
        } else {
            _proposal.status = Types.ProposalStatus.CANCELLED;

            IStaking(stakingAddress).removeShareHolderVotingId(
                msg.sender,
                proposalId
            );

            emit Cancelled(proposalId);
        }
    }

    /**
     * @param _stakingAddress staking address
     * @dev only owner can set staking address
     **/
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(
            _stakingAddress != address(0),
            "ShareHolderDao: staking address should not be the zero address"
        );

        stakingAddress = _stakingAddress;

        emit SetStakingAddress(stakingAddress);
    }

    /**
     * @param _developmentDaoAddress staking address
     * @dev only owner can set staking address
     **/
    function setDevelopmentDaoAddress(
        address _developmentDaoAddress
    ) external onlyOwner {
        require(
            _developmentDaoAddress != address(0),
            "ShareHolderDao: development dao address should not be the zero address"
        );

        developmentDaoAddress = _developmentDaoAddress;

        emit SetDevelopmentDaoAddress(developmentDaoAddress);
    }

    /**
     * @param _amount decrease amount
     **/
    function decreaseBudget(
        uint256 _amount
    ) external onlyDevelopmentDaoContract {
        require(
            _amount > 0,
            "ShareHolderDao: amount should be greater than the zero"
        );

        require(
            totalBudget >= _amount,
            "ShareHolderDao: amount should be less than the budget"
        );

        totalBudget -= _amount;

        emit BudgetDecreased(tx.origin, _amount);
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
            "ShareHolderDao: The zero address should not be the fee address"
        );

        require(
            amount > 0,
            "ShareHolderDao: amount should be greater than the zero"
        );

        uint256 balance = address(this).balance;

        require(amount <= balance, "ShareHolderDao: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "ShareHolderDao: Withdraw failed");

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
            "ShareHolderDao: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "ShareHolderDao: to address should not be the zero address"
        );
        require(
            amount > 0,
            "ShareHolderDao: amount should be greater than the zero"
        );

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "ShareHolderDao: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }

    /**
     * @param staker staker address
     * @param proposalId proposal id
     **/
    function evaluateVoteAmount(
        address staker,
        uint256 proposalId
    ) external onlyStakingContract {
        require(
            staker != address(0),
            "ShareHolderDao: staker should not be the zero address"
        );

        Types.VotingInfo storage _votingInfo = votingList[staker][proposalId];
        Types.ShareHolderProposal storage _shareHolderProposal = proposals[
            proposalId
        ];
        Types.StakeInfo memory _stakeInfo = IStaking(stakingAddress)
            .getStakingInfo(staker);
        uint256 _newStakeAmount = _stakeInfo.lopAmount + _stakeInfo.vLopAmount;
        uint256 _oldStakeAmount = _votingInfo.voteAmount;

        if (_votingInfo.isVoted) {
            if (_votingInfo.voteType) {
                // vote yes
                _shareHolderProposal.voteYesAmount =
                    _shareHolderProposal.voteYesAmount +
                    _newStakeAmount -
                    _oldStakeAmount;
            } else {
                // vote no
                _shareHolderProposal.voteNoAmount =
                    _shareHolderProposal.voteNoAmount +
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
}
