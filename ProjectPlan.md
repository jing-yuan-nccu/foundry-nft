# Foundry NFT Teaching Game Project Plan

## 1. Project Vision

This project extends the existing Foundry NFT teaching module into a game-like learning platform.

The core idea is:

+ Students first learn NFT development locally with Anvil.
+ Students can then try a casual NFT growth demo to understand dynamic metadata.
+ Finally, students complete Sepolia deployment quests. Each verified deployment advances a learning quest NFT.

The long-term goal is not only to teach contract deployment, but to make the learning process visible, verifiable, and more motivating through NFT progression.

## 2. Current Tracks

### Core Exercises

Path:

+ `src/exercises`
+ `test/exercises`
+ `script/exercises`

Purpose:

+ Teach local Anvil development.
+ Keep the required course path simple.
+ Cover IPFS-style NFT metadata and onchain SVG metadata.

Contracts:

+ `BasicNft`: ERC-721 with configurable base token URI.
+ `MoodNft`: ERC-721 with onchain SVG metadata and mood flipping.

These exercises should remain stable and beginner-friendly.

### Pokemon Growth Demo

Path:

+ `src/demos`
+ `test/demos`
+ `script/demos`
+ `frontend/pokemon`

Purpose:

+ Demonstrate casual draw-card gameplay.
+ Show how an NFT can change metadata based on time.
+ Provide a visual frontend for dynamic NFT behavior.

Main idea:

+ User mints a random Pokemon-style NFT.
+ The contract stores species and birth time.
+ `tokenURI()` changes based on elapsed time.
+ Metadata and SVG images are served locally by the frontend server.

This track is a prototype/demo, not the main teaching requirement.

### Sepolia Quest Extension

Path:

+ `src/quest`
+ `test/quest`
+ `script/quest`
+ `frontend/quest`

Purpose:

+ Turn Sepolia deployment into a learning game.
+ Verify that students actually deployed contracts to Sepolia.
+ Record verified progress on chain.
+ Let a quest NFT evolve as students complete stages.

Contracts:

+ `LearningQuest`: stores verified stage completion.
+ `LearningQuestNft`: reads `LearningQuest` progress and changes token metadata.

This is the main direction for the education-game concept.

## 3. Sepolia Quest Game Loop

The intended student flow:

1. Student connects wallet in the frontend.
2. Student deploys a required contract to Sepolia.
3. Student submits:
   + wallet address
   + quest stage
   + Sepolia contract address
   + optional deployment transaction hash
   + token id for ERC-721 checks
4. The frontend server checks the submitted contract through Sepolia RPC.
5. If verification passes, the submission is stored locally.
6. A verifier wallet finalizes the result on chain by calling:

```solidity
LearningQuest.completeStage(student, stage, contractAddress)
```

7. `LearningQuestNft.tokenURI()` reads the student's highest completed stage and shows the matching form.

## 4. Quest Stages

### Stage 1: ERC20

Student must deploy an ERC-20 style contract on Sepolia.

Verifier checks:

+ contract bytecode exists on Sepolia
+ `name()`
+ `symbol()`
+ `decimals()`
+ `totalSupply() > 0`
+ `balanceOf(student) > 0`
+ student ownership through `owner()` or deployment transaction sender

Result:

+ quest NFT evolves from base form to ERC20-cleared form

### Stage 2: ERC721

Student must deploy an ERC-721 style contract on Sepolia and mint at least one token.

Verifier checks:

+ contract bytecode exists on Sepolia
+ ERC165 supports ERC-721 interface
+ `name()`
+ `symbol()`
+ `ownerOf(tokenId) == student`
+ `tokenURI(tokenId)` is non-empty
+ student ownership through `owner()` or deployment transaction sender

Result:

+ quest NFT evolves to ERC721-cleared form

### Stage 3: Onchain ERC721

Student must deploy an ERC-721 whose metadata is fully onchain.

Verifier checks:

+ all Stage 2 checks
+ `tokenURI(tokenId)` starts with:

```text
data:application/json;base64,
```

+ decoded JSON contains `image`
+ image starts with:

```text
data:image/svg+xml;base64,
```

Result:

+ quest NFT reaches final form

## 5. Anti-Cheating Rules

The project currently uses three layers of control.

### Frontend

+ Students can only submit through selected quest stages.
+ Submission history shows pass/fail status.
+ The UI encourages sequential completion.

### Backend Verifier

+ Checks Sepolia bytecode with `eth_getCode`.
+ Checks required ABI calls.
+ Rejects reused contract addresses.
+ Rejects skipped stages based on local passed submission history.
+ Confirms student ownership through `owner()` or deployment transaction hash.

### Onchain Quest Contract

+ Only verifier wallets can call `completeStage`.
+ Students cannot mark themselves complete.
+ A student cannot complete the same stage twice.
+ A submitted contract address cannot be reused.
+ Students cannot skip directly to Stage 2 or Stage 3.

Important contract rule:

```solidity
if (stage > STAGE_ERC20 && !s_completions[student][stage - 1].completed) {
    revert LearningQuest__PreviousStageIncomplete();
}
```

This means a student cannot deploy only the final onchain ERC721 and directly receive the final NFT state.

## 6. Data Storage

### Onchain

Stored in `LearningQuest`:

+ student address
+ completed stage
+ submitted contract address
+ completion timestamp
+ highest completed stage
+ used contract addresses

This is the permanent progress source used by `LearningQuestNft`.

### Local Backend Database

Stored in:

```text
frontend/data/submissions.json
```

This file records:

+ passed submissions
+ failed submissions
+ error reason
+ checks performed
+ student address
+ contract address
+ stage
+ token id
+ timestamp

This is useful for TA review and debugging, but it is not the final source of NFT progression. The onchain quest contract is.

## 7. Frontend Server

The frontend server is intentionally lightweight.

File:

```text
frontend/server.js
```

Responsibilities:

+ serve the frontend app
+ serve local metadata and SVG assets
+ expose `POST /api/verify-submission`
+ expose `GET /api/submissions?student=...`
+ read `.env` for `SEPOLIA_RPC_URL`
+ verify Sepolia submissions through JSON-RPC

There is currently no npm package and no external Node dependency.

## 8. Deployment Plan

### Local

Core exercise deployment:

```bash
make anvil
make deploy
make mint
make deployMood
make mintMoodNft
```

Pokemon demo deployment:

```bash
forge script script/demos/DeployPokemonNft.s.sol:DeployPokemonNft --rpc-url http://127.0.0.1:8545 --private-key <ANVIL_KEY> --broadcast
```

Quest local deployment:

```bash
make deployQuest
```

### Sepolia

Required `.env` values:

```env
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
QUEST_VERIFIER_ADDRESS=
```

Deploy quest contracts:

```bash
make deployQuest-sepolia
```

The deployment returns:

+ `LearningQuest` address
+ `LearningQuestNft` address

These should be copied into `.env`:

```env
QUEST_CONTRACT_ADDRESS=
QUEST_NFT_CONTRACT_ADDRESS=
```

## 9. Current Limitations

+ The backend verifier currently validates submissions and stores results, but does not automatically send the `completeStage` transaction.
+ The verifier wallet must still finalize successful submissions on chain.
+ Local JSON storage is fine for a prototype, but a real classroom deployment should eventually use SQLite, Postgres, or another database.
+ Pokemon demo metadata is still served from the local frontend server.
+ Quest metadata is also local by default, though it can be moved to IPFS later.
+ The frontend combines Pokemon demo and Sepolia Quest UI in one page.

## 10. Recommended Next Steps

### Short Term

+ Deploy `LearningQuest` and `LearningQuestNft` to Sepolia.
+ Add a small script for verifier finalization:

```bash
completeStage(student, stage, contractAddress)
```

+ Add frontend fields for deployed quest contract addresses.
+ Let the frontend read `LearningQuest` and `LearningQuestNft` status directly.
+ Add classroom template contracts with `owner()` or `deployer()` to make verification easier.

### Medium Term

+ Move metadata and SVG assets to IPFS.
+ Replace local `submissions.json` with a proper database.
+ Add an instructor dashboard.
+ Add per-stage instructions and examples in the UI.
+ Add automatic verifier transaction sending after successful checks.

### Long Term

+ Support more quest paths beyond ERC20/ERC721/onchain ERC721.
+ Add class sections or cohorts.
+ Add leaderboard and completion analytics.
+ Add badge NFTs for specific achievements.
+ Consider account abstraction or sponsored verification transactions if students should not pay extra gas.

## 11. Design Principle

The required teaching path should stay simple.

The game layer should motivate students after they understand the basics, not make the first NFT lesson harder.

Therefore:

+ `exercises` stays stable and beginner-focused.
+ `demos` stays experimental.
+ `quest` becomes the advanced Sepolia learning game.
