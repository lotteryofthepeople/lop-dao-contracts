// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
    enum ProposalStatus {
        NONE,
        CREATED,
        CANCELLED,
        ACTIVE
    }

    enum JoinRequestStatus {
        NONE,
        CREATED,
        PASSED,
        CANCELLED
    }

    enum ProductMemberStatus {
        NONE,
        JOINNING,
        JOINED
    }

    struct ShareHolderProposal {
        uint256 budget;
        address owner;
        ProposalStatus status;
        uint256 voteYes;
        uint256 voteNo;
    }

    struct ProductJoinRequest {
        JoinRequestStatus status;
        address owner;
    }

    struct ProductMember {
        address owner;
        uint256 requestId;
        ProductMemberStatus status;
    }

    struct ProductProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteNo;
    }
}
