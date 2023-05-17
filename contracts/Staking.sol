// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/types.sol";

contract Staking is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // staking index
    Counters.Counter public stakingIndex;

    // ERC20 _LOP address
    address private _LOP;
    // ERC20 _vLOP address
    address private _vLOP;

    // minimum vote percent
    uint256 private _minVotePercent;

    // total lop amount
    uint256 public totalLopAmount;
    // total vlop amount
    uint256 public totalVLopAmount;

    //staker => stake info
    mapping(address => Types.StakeInfo) public stakingList;
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
     * @param toAddress to address
     * @param amount withdraw amount
     **/
    event WithdrawNative(address indexed toAddress, uint256 amount);
    /**
     * @param _LOP ERC20 _LOP address
     **/
    event SetLOP(address indexed _LOP);
    /**
     * @param _vLOP ERC20 _vLOP address
     **/
    event SetVLOP(address indexed _vLOP);
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
     * @param minVotePercent min vote percent
     **/
    event MinVoteUpdated(uint256 minVotePercent);

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

        emit SetLOP(_LOP);
        emit SetVLOP(_vLOP);
    }

    /**
     * @param amount staking amount of LOP
     **/
    function stakeLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.lopAmount += amount;
        IERC20(_LOP).safeTransferFrom(msg.sender, address(this), amount);

        emit StakeLop(msg.sender, amount);
    }

    /**
     * @param amount staking amount of vLOP
     **/
    function stakeVLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.vLopAmount += amount;
        IERC20(_vLOP).safeTransferFrom(msg.sender, address(this), amount);

        emit StakeVLop(msg.sender, amount);
    }

    /**
     * @param amount withdraw amount of LOP
     **/
    function withdrawLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.lopAmount -= amount;

        emit WithdrawLop(msg.sender, amount);
    }

    /**
     * @param amount withdraw amount of vLOP
     **/
    function withdrawVLop(uint256 amount) external {
        Types.StakeInfo storage _stakeInfo = stakingList[msg.sender];
        require(amount != 0, "Staking: amount should not be the zero amount");

        _stakeInfo.vLopAmount -= amount;

        emit WithdrawVLop(msg.sender, amount);
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
            "Staking: The zero address should not be the fee address"
        );

        require(amount > 0, "Staking: amount should be greater than the zero");

        uint256 balance = address(this).balance;

        require(amount <= balance, "TreasuryDao: No balance to withdraw");

        (bool success, ) = toAddress.call{value: balance}("");
        require(success, "TreasuryDao: Withdraw failed");

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

        emit Withdraw(token, toAddress, amount);
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
     * @param staker staker address
     * @dev get stake amount for LOP and vLOP
     **/
    function getStakeAmount(address staker) external view returns (uint256) {
        return stakingList[staker].lopAmount + stakingList[staker].vLopAmount;
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
}
