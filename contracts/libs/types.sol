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
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
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
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
    }

    struct DevelopmentProposal {
        string metadata;
        ProposalStatus status;
        address owner;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 productId;
        uint256 budget;
        uint256 createdAt;
    }

    struct EscrowProposal {
        ProposalStatus status;
        address owner;
        uint256 budget;
        uint256 voteYes;
        uint256 voteYesAmount;
        uint256 voteNo;
        uint256 voteNoAmount;
        uint256 createdAt;
    }

    struct StakeInfo {
        uint256 lopAmount;
        uint256 vLopAmount;
        uint256[] shareHolderVotingIds;
        uint256[] productVotingIds;
        uint256[] developmentVotingIds;
        uint256[] developmentEscrowVotingIds;
    }

    struct VotingInfo {
        bool isVoted;
        bool voteType; // true => VOTE Yes, false => VOTE No
        uint256 voteAmount;
    }
}
