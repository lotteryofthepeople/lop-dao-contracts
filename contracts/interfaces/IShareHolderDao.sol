// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IShareHolderDao {
    function decreaseBudget(uint256 _amount) external;

    function getShareHolderInfoByUser(
        address _user
    ) external view returns (Types.ShareHolderInfo memory _info);
}
