// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/types.sol";

interface IProductDao {
    function getProposalById(uint256 _proposalId)
        external
        returns (Types.ProductProposal memory _proposal);
}
