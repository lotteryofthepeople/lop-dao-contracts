# lop-dao-contracts

## `ShareHolderDao`

### `Functions`

#### WRITE

`setLOP`

set LOP ERC20 token address

| name  | type    | description        |
| :---- | :------ | :----------------- |
| \_LOP | address | The address of LOP |

<br>

`setVLOP`

set vLOP ERC20 token address

| name   | type    | description         |
| :----- | :------ | :------------------ |
| \_vLOP | address | The address of vLOP |

<br>

`createProposal`

create a new proposal

| name     | type    | description     |
| :------- | :------ | :-------------- |
| \_budget | uint256 | proposal budget |

<br>

`voteYes`

vote Yes for a proposal

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>

`voteNo`

vote No for a proposal

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>

`execute`

execute proposal

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>

#### READ

`LOP`

get LOP token address

    No params

<br>

`vLOP`

get vLOP token address

    No params

<br>

`minVote`

get the minimum vote number

    No params

<br>

`proposals`

get proposal info by id

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>

`isProposal`

check proposal status by creator

| name    | type    | description      |
| :------ | :------ | :--------------- |
| creator | address | proposal creator |

<br>

`isVoted`

check you vote proposal before

| name       | type    | description  |
| :--------- | :------ | :----------- |
| user       | address | user address |
| proposalId | uint256 | proposal id  |

<br>

### `EVENT`

`SetLOP`

emitted when update LOP address

| name  | type    | description |
| :---- | :------ | :---------- |
| \_LOP | address | LOP address |

<br>

`SetVLOP`

emitted when update vLOP address

| name   | type    | description    |
| :----- | :------ | :------------- |
| \_vLOP | address | \_vLOP address |

<br>

`ProposalCreated`

emitted when proposal is created

| name       | type    | description     |
| :--------- | :------ | :-------------- |
| owner      | address | owner address   |
| budget     | uint256 | proposal budget |
| proposalId | uint256 | proposal id     |

<br>

`VoteYes`

emitted when vote proposal as Yes

| name       | type    | description   |
| :--------- | :------ | :------------ |
| voter      | address | voter address |
| proposalId | uint256 | proposal id   |

<br>

`VoteNo`

emitted when vote proposal as No

| name       | type    | description   |
| :--------- | :------ | :------------ |
| voter      | address | voter address |
| proposalId | uint256 | proposal id   |

<br>

`Activated`

emitted when proposal is activated

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>

`Cancelled`

emitted when cancel proposal

| name       | type    | description |
| :--------- | :------ | :---------- |
| proposalId | uint256 | proposal id |

<br>
