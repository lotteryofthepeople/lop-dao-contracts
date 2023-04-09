// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShareHolderDao {
    function getLOP() external returns (address);

    function getVLOP() external returns (address);
}
