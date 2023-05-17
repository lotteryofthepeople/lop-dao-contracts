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

    enum MemberStatus {
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

    struct ShareHolderInfo {
        bool created;
        uint256 budget;
        string metadata;
    }

    struct JoinRequest {
        JoinRequestStatus status;
        address owner;
    }

    struct Member {
        address owner;
        uint256 requestId;
        MemberStatus status;
    }

    struct ProductProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteNo;
    }

    struct DevelopmentProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteNo;
        uint256 productId;
        uint256 budget;
    }

    struct EscrowProposal {
        ProposalStatus status;
        address owner;
        uint256 budget;
        uint256 voteYes;
        uint256 voteNo;
    }

    struct StakeInfo {
        uint256 lopAmount;
        uint256 vLopAmount;
    }
}
