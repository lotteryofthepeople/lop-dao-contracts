// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/types.sol";
import "./interfaces/IShareHolderDao.sol";
import "./interfaces/IProductDao.sol";
import "./interfaces/IDevelopmentDao.sol";

contract Staking is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // staking index
    Counters.Counter public stakingIndex;

    // share holder dao address
    address public SHARE_HOLDER_ADDRESS;
    // product dao address
    address public PRODUCT_ADDRESS;
    // development dao address
    address public DEVELOPMENT_ADDRESS;

    uint256 private _PROPOSAL_EXPIRED_DATE;

    // max shareholder voting count
    uint256 private _MAX_SHARE_HOLDER_VOTING_COUNT;
    // max prodcut voting count
    uint256 private _MAX_PRODUCT_VOTING_COUNT;
    // max development voting count
    uint256 private _MAX_DEVELOPMENT_VOTING_COUNT;

    // ERC20 _LOP address
    address private _LOP;
    // ERC20 _vLOP address
    address private _vLOP;

    // minimum vote percent
    uint256 private _minVotePercent;

    //staker => stake info
    mapping(address => Types.StakeInfo) public _stakingList;
    /**
     * @param staker address of staker
     * @param amount staking amount
     **/
    event StakeLop(address indexed staker, uint256 amount);
    /**
     * @param staker address of staker
     * @param amount staking amount
     **/
    event StakeVLop(address indexed staker, uint256 amount);
    /**
     * @param withdrawer address of withdrawer
     * @param amount withdraw amount of LOP
     **/
    event WithdrawLop(address indexed withdrawer, uint256 amount);
    /**
     * @param withdrawer address of withdrawer
     * @param amount withdraw amount of LOP
     **/
    event WithdrawVLop(address indexed withdrawer, uint256 amount);
    /**
     * @param staker address of staker
     * @param shareHolderProposalId share holder proposal id
     **/
    event AddShareHolderVotingId(
        address indexed staker,
        uint256 shareHolderProposalId
    );
    /**
     * @param staker address of staker
     * @param shareHolderProposalId share holder proposal id
     **/
    event RemoveShareHolderVotingId(
        address indexed staker,
        uint256 shareHolderProposalId
    );
    /**
     * @param staker address of staker
     * @param productProposalId product proposal id
     **/
    event AddProductVotingId(address indexed staker, uint256 productProposalId);
    /**
     * @param staker address of staker
     * @param productProposalId product proposal id
     **/
    event RemoveProductVotingId(
        address indexed staker,
        uint256 productProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentProposalId development proposal id
     **/
    event AddDevelopmentVotingId(
        address indexed staker,
        uint256 developmentProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentProposalId development proposal id
     **/
    event RemoveDevelopmentVotingId(
        address indexed staker,
        uint256 developmentProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentEscrowProposalId development escrow proposal id
     **/
    event AddDevelopmentEscrowVotingId(
        address indexed staker,
        uint256 developmentEscrowProposalId
    );
    /**
     * @param staker address of staker
     * @param developmentEscrowProposalId development escrow proposal id
     **/
    event RemoveDevelopmentEscrowVotingId(
        address indexed staker,
        uint256 developmentEscrowProposalId
    );
    /**
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event AdminWithdrawNative(address indexed toAddress, uint256 amount);
    /**
     * @param token token address
     * @param toAddress destination address
     * @param amount withdraw amount
     **/
    event AdminWithdraw(
        address indexed token,
        address indexed toAddress,
        uint256 amount
    );
    /**
     * @param _LOP ERC20 _LOP address
     **/
    event SetLOP(address indexed _LOP);
    /**
     * @param _vLOP ERC20 _vLOP address
     **/
    event SetVLOP(address indexed _vLOP);

    /**
     * @param minVotePercent min vote percent
     **/
    event MinVoteUpdated(uint256 minVotePercent);

    /**
     * @param _proposalExpiredDate proposal expired date
     **/
    event SetProposalExpiredDate(uint256 _proposalExpiredDate);

    /**
     * @param _MAX_SHARE_HOLDER_VOTING_COUNT max share holder voting count
     **/
    event SetMaxShareHolderVotingCount(uint256 _MAX_SHARE_HOLDER_VOTING_COUNT);

    /**
     * @param _MAX_PRODUCT_VOTING_COUNT max product voting count
     **/
    event SetMaxProductVotingCount(uint256 _MAX_PRODUCT_VOTING_COUNT);

    /**
     * @param _MAX_DEVELOPMENT_VOTING_COUNT max development voting count
     **/
    event SetMaxDevelopmentVotingCount(uint256 _MAX_DEVELOPMENT_VOTING_COUNT);

    /**
     * @param SHARE_HOLDER_ADDRESS share holder address
     **/
    event SetShareHolderAddress(address SHARE_HOLDER_ADDRESS);

    /**
     * @param PRODUCT_ADDRESS product address
     **/
    event SetProductAddress(address PRODUCT_ADDRESS);

    /**
     * @param DEVELOPMMENT_ADDRESS development address
     **/
    event SetDevelopmentAddress(address DEVELOPMMENT_ADDRESS);

    modifier onlyShareHolderContract() {
        require(
            msg.sender == SHARE_HOLDER_ADDRESS,
            "Staking: Only share holder contract can access this function"
        );
        _;
    }

    modifier onlyProductContract() {
        require(
            msg.sender == PRODUCT_ADDRESS,
            "Staking: Only product contract can access this function"
        );
        _;
    }

    modifier onlyDevelopmentContract() {
        require(
            msg.sender == DEVELOPMENT_ADDRESS,
            "Staking: Only development contract can access this function"
        );
        _;
    }

    constructor(address LOP_, address vLOP_, uint256 minVotePercent_) {
        require(
            LOP_ != address(0),
            "Staking: LOP address hould not be the zero address"
        );
        require(
            vLOP_ != address(0),
            "Staking: vLOP address hould not be the zero address"
        );

        require(
            minVotePercent_ > 0,
            "Staking: min vote percent should be greater than the zero"
        );

        _LOP = LOP_;
        _vLOP = vLOP_;

        _minVotePercent = minVotePercent_;

        _MAX_SHARE_HOLDER_VOTING_COUNT = 5;
        _MAX_PRODUCT_VOTING_COUNT = 5;
        _MAX_DEVELOPMENT_VOTING_COUNT = 5;

        // 14 days
        _PROPOSAL_EXPIRED_DATE = 14 * 24 * 60 * 60;

        emit SetLOP(_LOP);
        emit SetVLOP(_vLOP);
        emit SetMaxShareHolderVotingCount(_MAX_SHARE_HOLDER_VOTING_COUNT);
        emit SetMaxDevelopmentVotingCount(_MAX_DEVELOPMENT_VOTING_COUNT);
        emit SetMaxProductVotingCount(_MAX_PRODUCT_VOTING_COUNT);
        emit SetProposalExpiredDate(_PROPOSAL_EXPIRED_DATE);
    }

    /**
     * @param amount staking amount of LOP
     **/
    function stakeLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.lopAmount += amount;
        IERC20(_LOP).safeTransferFrom(msg.sender, address(this), amount);

        _evaluateShareHolderDao(msg.sender);

        emit StakeLop(msg.sender, amount);
    }

    /**
     * @param amount staking amount of vLOP
     **/
    function stakeVLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.vLopAmount += amount;
        IERC20(_vLOP).safeTransferFrom(msg.sender, address(this), amount);

        _evaluateShareHolderDao(msg.sender);

        emit StakeVLop(msg.sender, amount);
    }

    /**
     * @dev withdraw LOP token
     **/
    function withdrawLop() external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(
            _stakeInfo.lopAmount > 0,
            "Staking: amount should not be the zero amount"
        );

        uint256 _amount = _stakeInfo.lopAmount;
        _stakeInfo.lopAmount = 0;
        IERC20(_LOP).safeTransfer(msg.sender, _amount);

        _evaluateShareHolderDao(msg.sender);

        emit WithdrawLop(msg.sender, _amount);
    }

    /**
     * @dev withdraw vLOP token
     **/
    function withdrawVLop() external {
        Types.StakeInfo storage _stakeInfo = _stakingList[msg.sender];
        require(
            _stakeInfo.vLopAmount > 0,
            "Staking: amount should not be the zero amount"
        );

        uint256 _amount = _stakeInfo.vLopAmount;
        _stakeInfo.vLopAmount = 0;
        IERC20(_vLOP).safeTransfer(msg.sender, _amount);

        _evaluateShareHolderDao(msg.sender);

        emit WithdrawVLop(msg.sender, _amount);
    }

    /**
     * @param _staker address of staker
     * @param _shareHolderProposalId share holder proposal id
     ** */
    function addShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external onlyShareHolderContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.shareHolderVotingIds.push(_shareHolderProposalId);

        emit AddShareHolderVotingId(_staker, _shareHolderProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _shareHolderProposalId share holder proposal id
     ** */
    function removeShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external onlyShareHolderContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.shareHolderVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.shareHolderVotingIds[i] == _shareHolderProposalId) {
                _stakeInfo.shareHolderVotingIds[i] = _stakeInfo
                    .shareHolderVotingIds[_votingIdsLen - 1];
                _stakeInfo.shareHolderVotingIds.pop();
                break;
            }
        }

        emit RemoveShareHolderVotingId(_staker, _shareHolderProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _productProposalId product proposal id
     ** */
    function addProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external onlyProductContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.productVotingIds.push(_productProposalId);

        emit AddProductVotingId(_staker, _productProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _productProposalId product proposal id
     ** */
    function removeProductVotingId(
        address _staker,
        uint256 _productProposalId
    ) external onlyProductContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.productVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.productVotingIds[i] == _productProposalId) {
                _stakeInfo.productVotingIds[i] = _stakeInfo.productVotingIds[
                    _votingIdsLen - 1
                ];
                _stakeInfo.productVotingIds.pop();
                break;
            }
        }

        emit RemoveProductVotingId(_staker, _productProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentProposalId development proposal id
     ** */
    function addDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.developmentVotingIds.push(_developmentProposalId);

        emit AddDevelopmentVotingId(_staker, _developmentProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentProposalId development proposal id
     ** */
    function removeDevelopmentVotingId(
        address _staker,
        uint256 _developmentProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.developmentVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (_stakeInfo.developmentVotingIds[i] == _developmentProposalId) {
                _stakeInfo.developmentVotingIds[i] = _stakeInfo
                    .developmentVotingIds[_votingIdsLen - 1];
                _stakeInfo.developmentVotingIds.pop();
                break;
            }
        }

        emit RemoveDevelopmentVotingId(_staker, _developmentProposalId);
    }

    /**
     * @param _staker address of staker
     * @param _developmentEscrowProposalId development proposal id
     ** */
    function addDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentEscrowProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        _stakeInfo.developmentEscrowVotingIds.push(
            _developmentEscrowProposalId
        );

        emit AddDevelopmentEscrowVotingId(
            _staker,
            _developmentEscrowProposalId
        );
    }

    /**
     * @param _staker address of staker
     * @param _developmentEscrowProposalId development proposal id
     ** */
    function removeDevelopmentEscrowVotingId(
        address _staker,
        uint256 _developmentEscrowProposalId
    ) external onlyDevelopmentContract {
        Types.StakeInfo storage _stakeInfo = _stakingList[_staker];

        uint256 _votingIdsLen = _stakeInfo.developmentEscrowVotingIds.length;
        for (uint256 i = 0; i < _votingIdsLen; i++) {
            if (
                _stakeInfo.developmentEscrowVotingIds[i] ==
                _developmentEscrowProposalId
            ) {
                _stakeInfo.developmentEscrowVotingIds[i] = _stakeInfo
                    .developmentEscrowVotingIds[_votingIdsLen - 1];
                _stakeInfo.developmentEscrowVotingIds.pop();
                break;
            }
        }

        emit RemoveDevelopmentVotingId(_staker, _developmentEscrowProposalId);
    }

    /**
     * @param  toAddress address to receive fee
     * @param amount withdraw native token amount
     **/
    function adminWithdrawNative(
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            toAddress != address(0),
            "Staking: The zero address should not be the fee address"
        );

        require(amount > 0, "Staking: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "Staking: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "Staking: Withdraw failed");

        emit AdminWithdrawNative(toAddress, balance);
    }

    /**
     * @param token token address
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    function adminWithdraw(
        address token,
        address payable toAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "Staking: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "Staking: to address should not be the zero address"
        );
        require(amount > 0, "Staking: amount should be greater than the zero");

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "Staking: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit AdminWithdraw(token, toAddress, amount);
    }

    /**
     * @param _shareHolderAddress share holder address
     * @dev only owner can set share holder address
     **/
    function setShareHolderAddress(
        address _shareHolderAddress
    ) external onlyOwner {
        require(
            _shareHolderAddress != address(0),
            "Staking: share holder address should not be the zero"
        );

        SHARE_HOLDER_ADDRESS = _shareHolderAddress;

        emit SetShareHolderAddress(SHARE_HOLDER_ADDRESS);
    }

    /**
     * @param _productAddress product address
     * @dev only owner can set product address
     **/
    function setProductAddress(address _productAddress) external onlyOwner {
        require(
            _productAddress != address(0),
            "Staking: product address should not be the zero"
        );

        PRODUCT_ADDRESS = _productAddress;

        emit SetProductAddress(PRODUCT_ADDRESS);
    }

    /**
     * @param _developmentAddress development address
     * @dev only owner can set develometn address
     **/
    function setDevelopmentAddress(
        address _developmentAddress
    ) external onlyOwner {
        require(
            _developmentAddress != address(0),
            "Staking: development should not be the zero"
        );

        DEVELOPMENT_ADDRESS = _developmentAddress;

        emit SetDevelopmentAddress(DEVELOPMENT_ADDRESS);
    }

    /**
     * @param LOP_ ERC20 _LOP address
     * @dev only owner can set _LOP address
     **/
    function setLOP(address LOP_) external onlyOwner {
        require(
            LOP_ != address(0),
            "Staking: LOP address hould not be the zero address"
        );

        _LOP = LOP_;

        emit SetLOP(_LOP);
    }

    /**
     * @param vLOP_ ERC20 _vLOP address
     * @dev only owner can set _vLOP address
     **/
    function setVLOP(address vLOP_) external onlyOwner {
        require(
            vLOP_ != address(0),
            "Staking: vLOP address hould not be the zero address"
        );

        _vLOP = vLOP_;

        emit SetLOP(_vLOP);
    }

    /**
     * @param minVotePercent_ min vote percent
     * @dev only owner can set minVotePercent
     **/
    function setMinVotePercent(uint256 minVotePercent_) external onlyOwner {
        require(
            minVotePercent_ > 0,
            "Staking: min vote should be greater than the zero"
        );

        _minVotePercent = minVotePercent_;

        emit MinVoteUpdated(_minVotePercent);
    }

    /**
     * @param _propsalExpiredDate max shareholder voting count
     **/
    function setProposalExpriedDate(
        uint256 _propsalExpiredDate
    ) external onlyOwner {
        require(
            _propsalExpiredDate > 0,
            "Staking: proposal expired should be greater than the zero"
        );

        _PROPOSAL_EXPIRED_DATE = _propsalExpiredDate;

        emit SetProposalExpiredDate(_propsalExpiredDate);
    }

    /**
     * @param _maxShareHolderVotingCount max shareholder voting count
     * @dev only owner can set max share holder voting count
     **/
    function setMaxShareHolderVotingCount(
        uint256 _maxShareHolderVotingCount
    ) external onlyOwner {
        require(
            _maxShareHolderVotingCount > 0,
            "Staking: max share holder voting count should be greater than the zero"
        );

        _MAX_SHARE_HOLDER_VOTING_COUNT = _maxShareHolderVotingCount;

        emit SetMaxShareHolderVotingCount(_MAX_SHARE_HOLDER_VOTING_COUNT);
    }

    /**
     * @param _maxProductVotingCount max product voting count
     * @dev only owner can set max product voting count
     **/
    function setMaxProductVotingCount(
        uint256 _maxProductVotingCount
    ) external onlyOwner {
        require(
            _maxProductVotingCount > 0,
            "Staking: max product voting count should be greater than the zero"
        );

        _MAX_PRODUCT_VOTING_COUNT = _maxProductVotingCount;

        emit SetMaxProductVotingCount(_MAX_PRODUCT_VOTING_COUNT);
    }

    /**
     * @param _maxDevelopmentVotingCount max development voting count
     * @dev only owner can set max development voting count
     **/
    function setMaxDevelopmentVotingCount(
        uint256 _maxDevelopmentVotingCount
    ) external onlyOwner {
        require(
            _maxDevelopmentVotingCount > 0,
            "Staking: max development voting count should be greater than the zero"
        );

        _MAX_DEVELOPMENT_VOTING_COUNT = _maxDevelopmentVotingCount;

        emit SetMaxDevelopmentVotingCount(_MAX_DEVELOPMENT_VOTING_COUNT);
    }

    /**
     * @param staker staker address
     * @dev get stake amount for LOP and vLOP
     **/
    function getStakeAmount(address staker) external view returns (uint256) {
        return _stakingList[staker].lopAmount + _stakingList[staker].vLopAmount;
    }

    function getLOP() external view returns (address) {
        return _LOP;
    }

    function getVLOP() external view returns (address) {
        return _vLOP;
    }

    function getMinVotePercent() external view returns (uint256) {
        return _minVotePercent;
    }

    function getStakingInfo(
        address staker
    ) external view returns (Types.StakeInfo memory) {
        return _stakingList[staker];
    }

    function MAX_SHARE_HOLDER_VOTING_COUNT() external view returns (uint256) {
        return _MAX_SHARE_HOLDER_VOTING_COUNT;
    }

    function MAX_PRODUCT_VOTING_COUNT() external view returns (uint256) {
        return _MAX_PRODUCT_VOTING_COUNT;
    }

    function MAX_DEVELOPMENT_VOTING_COUNT() external view returns (uint256) {
        return _MAX_DEVELOPMENT_VOTING_COUNT;
    }

    function getProposalExpiredDate() external view returns (uint256) {
        return _PROPOSAL_EXPIRED_DATE;
    }

    function _evaluateShareHolderDao(address _staker) internal {
        Types.StakeInfo memory _stakingInfo = _stakingList[_staker];

        for (uint256 i = 0; i < _stakingInfo.shareHolderVotingIds.length; i++) {
            IShareHolderDao(SHARE_HOLDER_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.shareHolderVotingIds[i]
            );
        }

        for (uint256 i = 0; i < _stakingInfo.productVotingIds.length; i++) {
            IProductDao(PRODUCT_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.productVotingIds[i]
            );
        }

        for (uint256 i = 0; i < _stakingInfo.developmentVotingIds.length; i++) {
            IDevelopmentDao(DEVELOPMENT_ADDRESS).evaluateVoteAmount(
                _staker,
                _stakingInfo.developmentVotingIds[i]
            );
        }

        for (
            uint256 i = 0;
            i < _stakingInfo.developmentEscrowVotingIds.length;
            i++
        ) {
            IDevelopmentDao(DEVELOPMENT_ADDRESS).evaluateEscrowVoteAmount(
                _staker,
                _stakingInfo.developmentEscrowVotingIds[i]
            );
        }
    }
}
