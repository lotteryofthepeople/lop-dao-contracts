// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/types.sol";

contract TreasuryDao is Ownable {
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

    constructor() {}

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

        IERC20(token).transfer(toAddress, amount);

        emit Withdraw(token, toAddress, amount);
    }
}
