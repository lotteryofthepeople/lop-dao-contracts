// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IShareHolderDao {
    function decreaseBudget(uint256 _amount) external;

    function getMyVoteType(
        address _user,
        uint256 _proposalId
    ) external view returns (bool);

    function totalBudget() external view returns (uint256);

    function evaluateVoteAmount(address staker, uint256 proposalId) external;
}
