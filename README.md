# VoteChain

A decentralized community governance and proposal validation platform built on the Stacks blockchain. VoteChain enables community members to submit, endorse, and rate governance proposals while earning tokens based on participation activities and engagement assessments.

## Features

- **Member Registration**: Proposers, endorsers, and supporters can register and manage their profiles
- **Proposal Submission**: Community members can submit governance proposals with cryptographic integrity
- **Endorsement System**: Multiple members can endorse proposals to establish community support
- **Support Tracking**: Track and measure community support for governance initiatives
- **Engagement Rating System**: Community-driven rating system for proposal engagement quality
- **Token Rewards**: Members earn tokens for endorsement activities and high-engagement proposals
- **Approval System**: Build member reputation through consistent participation and quality proposals

## Smart Contract Functions

### Member Management
- `register-member`: Register as a proposer, endorser, or supporter
- `update-member`: Update member profile information

### Governance Operations
- `submit-proposal`: Submit new governance proposals for community review
- `endorse-proposal`: Endorse proposals submitted by other community members
- `support-proposal`: Provide support and backing for verified proposals
- `rate-proposal-engagement`: Rate the engagement quality and community impact of proposals

### Read-Only Functions
- `get-member-info`: Retrieve member profile and statistics
- `get-proposal`: Get detailed proposal information and endorsement history
- `get-total-proposals`: Get total number of proposals in the system

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Register as a member using `register-member`
3. Start submitting proposals or endorsing existing ones
4. Participate in the engagement rating system to earn tokens and build reputation

## Token Economics

- **Endorsement Reward**: 5 tokens per proposal endorsement
- **Approval Reward**: 50 tokens when proposal reaches verified status
- **Engagement Reward**: 20 tokens for high-engagement proposal ratings
- **Rating Participation**: 2 tokens per engagement rating submitted

## Requirements

- Stacks blockchain connection
- Clarinet for local development and testing
- Valid member registration to participate in community governance
