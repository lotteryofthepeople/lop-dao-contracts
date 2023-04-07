// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20LOP is ERC20, Ownable {
    /**
     * @dev minter list
     **/
    mapping(address => bool) public isMinter;

    /**
     * @param minter token minter
     **/
    event AddMinter(address indexed minter);
    /**
     * @param minter token minter
     **/
    event RemoveMinter(address indexed minter);

    /**
     * @param initialSupply token initial supply
     **/
    constructor(uint256 initialSupply) ERC20("Lottery of the People", "LOP") {
        require(
            initialSupply > 0,
            "ERC20LOP: initial supply should be greater than the zero"
        );

        _mint(msg.sender, initialSupply);

        isMinter[msg.sender] = true;

        emit AddMinter(msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(isMinter[msg.sender], "ERC20LOP: Only minters can mint");
        _mint(to, amount);
    }

    /**
     * @param user address of user
     * @dev add user to minter list
     **/
    function addMinter(address user) public onlyOwner {
        require(
            user != address(0),
            "ERC20LOP: user should not be the zero address"
        );
        require(!isMinter[user], "ERC20LOP: user is already setted as minter");

        isMinter[user] = true;

        emit AddMinter(user);
    }

    /**
     * @param user address of user
     * @dev remove user from minter list
     **/
    function removeMinter(address user) public onlyOwner {
        require(
            user != address(0),
            "ERC20LOP: minter should not be the zero address"
        );
        require(isMinter[user], "ERC20LOP: user is not minter");

        isMinter[user] = false;

        emit RemoveMinter(user);
    }
}
