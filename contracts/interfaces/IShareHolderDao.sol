// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IShareHolderDao {
    function getLOP() external returns (address);

    function getVLOP() external returns (address);

    function getShareHolderInfoByUser(address _user) external returns (Types.ShareHolderInfo memory _info);
}
