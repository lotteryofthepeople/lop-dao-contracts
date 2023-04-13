// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20LOP {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
}
