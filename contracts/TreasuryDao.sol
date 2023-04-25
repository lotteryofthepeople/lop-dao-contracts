// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IShareHolderDao.sol";

contract TreasuryDao is Ownable {
    using SafeERC20 for IERC20;

    // usdc token address
    address public USDC;

    // share holder dao address
    address public shareHolderDao;

    // swap status
    bool public swapStatus;

    // user => usdc depoit amount
    mapping(address => uint256) public usdcDeopist;

    // user => lop deposit amount
    mapping(address => uint256) public lopDeposit;

    /**
     * @param creator swap creator
     * @param amount swap amount
     * */
    event SwappedLopToUsdc(address indexed creator, uint256 amount);

    /**
     * @param creator swap creator
     * @param amount swap amount
     * */
    event SwappedUsdcToLop(address indexed creator, uint256 amount);

    /**
     * @param status new swap status
     **/
    event SwapStatusUpdated(bool status);

    /**
     * @param _shareHolderDao share holder dao address
     **/
    event ShareHolderUpdated(address indexed _shareHolderDao);

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
     * @param owner deposit owner
     * @param amount deposit amount
     **/
    event DepositedUSDC(address indexed owner, uint256 amount);

    /**
     * @param owner deposit owner
     * @param amount deposit amount
     **/
    event DepositedLOP(address indexed owner, uint256 amount);

    /**
     * @param _USDC USDC token address
     **/
    constructor(address _USDC, address _shareHolderDao) {
        require(
            _USDC != address(0),
            "TreasuryDao: USDC should not be the zero address"
        );
        require(
            _shareHolderDao != address(0),
            "TreasuryDao: share holder dao address should not be the zero address"
        );

        USDC = _USDC;

        shareHolderDao = _shareHolderDao;

        emit ShareHolderUpdated(shareHolderDao);
    }

    /**
     * @param amount deposit amount
     **/
    function depositLOP(uint256 amount) external {
        require(amount > 0, "TreasuryDao: amount should not be the zero");

        address _LOP = IShareHolderDao(shareHolderDao).getLOP();

        require(
            IERC20(_LOP).balanceOf(msg.sender) >= amount,
            "TreasuryDao: balance error of LOP"
        );
        require(
            IERC20(_LOP).allowance(msg.sender, address(this)) >= amount,
            "TreasuryDao: approve allowance is not enough in LOP"
        );

        lopDeposit[msg.sender] += amount;

        IERC20(_LOP).safeTransferFrom(msg.sender, address(this), amount);

        emit DepositedLOP(msg.sender, amount);
    }

    /**
     * @param amount deposit amount
     **/
    function depositUsdc(uint256 amount) external {
        require(amount > 0, "TreasuryDao: amount should not be the zero");

        require(
            IERC20(USDC).balanceOf(msg.sender) >= amount,
            "TreasuryDao: balance error of USDC"
        );
        require(
            IERC20(USDC).allowance(msg.sender, address(this)) >= amount,
            "TreasuryDao: approve allowance is not enough in USDC"
        );

        usdcDeopist[msg.sender] += amount;

        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);

        emit DepositedUSDC(msg.sender, amount);
    }

    /**
     * @param amount swap amount
     **/
    function swapLopToUsdc(uint256 amount) external {
        require(swapStatus, "TreasuryDao: swap is not enabled");
        require(
            amount > 0,
            "TreasuryDao: amount should be greater than the zero"
        );
        address _LOP = IShareHolderDao(shareHolderDao).getLOP();
        require(
            IERC20(_LOP).balanceOf(msg.sender) >= amount,
            "TreasuryDao: You have not enough LOP token"
        );
        require(
            IERC20(_LOP).allowance(msg.sender, address(this)) >= amount,
            "TreasuryDao: Approve allownance error for LOP"
        );
        require(
            IERC20(USDC).balanceOf(address(this)) >= amount,
            "TreasuryDao: USDC balance error"
        );

        IERC20(_LOP).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(USDC).safeTransfer(msg.sender, amount);

        emit SwappedLopToUsdc(msg.sender, amount);
    }

    /**
     * @param amount swap amount
     **/
    function swapUsdcToLop(uint256 amount) external {
        require(swapStatus, "TreasuryDao: swap is not enabled");
        require(
            amount > 0,
            "TreasuryDao: amount should be greater than the zero"
        );
        require(
            IERC20(USDC).balanceOf(msg.sender) >= amount,
            "TreasuryDao: You have not enough USDC token"
        );
        require(
            IERC20(USDC).allowance(msg.sender, address(this)) >= amount,
            "TreasuryDao: Approve allownance error for USDC"
        );

        address _LOP = IShareHolderDao(shareHolderDao).getLOP();
        
        require(
            IERC20(_LOP).balanceOf(address(this)) >= amount,
            "TreasuryDao: LOP balance error"
        );

        IERC20(USDC).safeTransferFrom(msg.sender, address(this), amount);

        IERC20(_LOP).safeTransfer(msg.sender, amount);

        emit SwappedUsdcToLop(msg.sender, amount);
    }

    /**
     * @param status a new swap status
     **/
    function setSwapStatus(bool status) external onlyOwner {
        require(swapStatus != status, "TresuryDao: dupulcated status");

        swapStatus = status;

        emit SwapStatusUpdated(swapStatus);
    }

    /**
     * @param _shareHolderDao share holder dao address
     **/
    function setShareHolderDao(address _shareHolderDao) external onlyOwner {
        require(
            _shareHolderDao != address(0),
            "TreasuryDao: share holder dao address should not be the zero address"
        );

        shareHolderDao = _shareHolderDao;

        emit ShareHolderUpdated(_shareHolderDao);
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
            "TreasuryDao: The zero address should not be the fee address"
        );

        require(
            amount > 0,
            "TreasuryDao: amount should be greater than the zero"
        );

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
            "TreasuryDao: token address should not be the zero address"
        );
        require(
            toAddress != address(0),
            "TreasuryDao: to address should not be the zero address"
        );
        require(
            amount > 0,
            "TreasuryDao: amount should be greater than the zero"
        );

        uint256 balance = IERC20(token).balanceOf(address(this));

        require(amount <= balance, "TreasuryDao: No balance to withdraw");

        IERC20(token).safeTransfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }
}
