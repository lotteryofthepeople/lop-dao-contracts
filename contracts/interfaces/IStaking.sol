// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IStaking {
    function getStakeAmount(address staker) external view returns (uint256);

    function getLOP() external view returns (address);

    function getVLOP() external view returns (address);

    function getMinVotePercent() external view returns (uint256);

    function getStakingInfo(
        address staker
    ) external view returns (Types.StakeInfo memory);

    function MAX_SHARE_HOLDER_VOTING_COUNT() external view returns (uint256);

    function MAX_PRODUCT_VOTING_COUNT() external view returns (uint256);

    function MAX_DEVELOPMENT_VOTING_COUNT() external view returns (uint256);

    function addShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external;

    function removeShareHolderVotingId(
        address _staker,
        uint256 _shareHolderProposalId
    ) external;
}