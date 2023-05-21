// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IDevelopmentDao {
    function evaluateVoteAmount(address staker, uint256 proposalId) external;
    function evaluateEscrowVoteAmount(address staker, uint256 proposalId) external;
}
