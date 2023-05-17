// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function getStakeAmount(address staker) external view returns (uint256);

    function getLOP() external view returns (address);

    function getVLOP() external view returns (address);

    function getMinVotePercent() external view returns (uint256);
}
