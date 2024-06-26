// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IProductDao {
    function evaluateVoteAmount(address staker, uint256 proposalId) external;

    function getProposalById(
        uint256 _proposalId
    ) external view returns (Types.ProductProposal memory _proposal);
}
