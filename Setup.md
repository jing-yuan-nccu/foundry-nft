# Setup

This document explains how to set up the environment for this `foundry-nft` project.

This repository is intended to follow:

+ [QuPepe/blockchain](https://github.com/QuPepe/blockchain)

If students have already completed the teacher's earlier materials, most of the required software should already be installed.

## What You Need

+ Git
+ Foundry
+ Visual Studio Code
+ Git Bash (Windows) or a terminal (Mac/Linux)

## Recommended Versions

+ Git: latest stable version
+ Foundry: `1.5.1` or newer
+ Solidity compiler: no separate installation required
+ Node.js: not required for the current project

## Why Node.js Is Not Required Here

+ This repository currently uses Foundry only.
+ There is no frontend app and no npm package in this project.
+ So you do not need `node` or `npm` to build, test, deploy, or interact with the contracts.

## Install Git

### Windows

+ Install [Git for Windows](https://gitforwindows.org/).
+ During setup, the default options are usually fine.
+ After installation, open `Git Bash`.

### Mac

+ Install Git with Homebrew:
  ```bash
  brew install git
  ```

## Install Foundry

+ Open Git Bash (Windows) or a terminal (Mac/Linux).
+ Install Foundry:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  ```
+ Close the terminal and open it again.
+ Install the Foundry tools:
  ```bash
  foundryup
  ```
+ Check the installed version:
  ```bash
  forge --version
  anvil --version
  cast --version
  ```

## Recommended Foundry Version for This Project

+ This project was verified with:
  ```bash
  forge Version: 1.5.1
  ```
+ If your Foundry version is much older, upgrade it:
  ```bash
  foundryup
  ```

## Solidity Compiler

+ You do not need to install `solc` manually.
+ Foundry will automatically install and use the required compiler version when you run:
  ```bash
  forge build
  ```
+ The contracts in this repository use:
  ```solidity
  pragma solidity ^0.8.18;
  ```
+ In practice, Foundry may compile them with a newer compatible `0.8.x` compiler version.

## Install Visual Studio Code

+ Install [Visual Studio Code](https://code.visualstudio.com/).
+ Recommended extensions:
+ `Solidity` by Juan Blanco
+ `Even Better TOML`

## Clone the Repository

+ Clone this repository:
  ```bash
  git clone https://github.com/jing-yuan-nccu/foundry-nft.git
  ```
+ Enter the project folder:
  ```bash
  cd foundry-nft
  ```

## Install Project Dependencies

+ This project keeps its Foundry libraries in the repository as Git submodules.
+ Initialize and download them after cloning:
  ```bash
  git submodule update --init --recursive
  ```
+ The main dependencies used in this project are:
+ `forge-std`
+ `openzeppelin-contracts`
+ `foundry-devops`

## Dependency Versions Used in This Project

+ `forge-std`
+ locked by `foundry.lock`
+ `openzeppelin-contracts`
+ locked to commit `5fd1781b1454fd1ef8e722282f86f9293cacf256`
+ `foundry-devops`
+ locked to tag `0.4.0`
+ If you want the exact locked dependency versions, keep `foundry.lock` and the Git submodules unchanged.
+

## Do Not Mix Dependency Installation Methods

+ For this teaching repository, prefer the Git submodule workflow above.
+ Do not run `forge install` unless you intentionally want to change the dependency layout or versions.
+ If students all use `git submodule update --init --recursive`, the project structure will stay consistent across machines.

## Build the Project

+ Run:
  ```bash
  forge build
  ```
+ If the build succeeds, your environment is ready.

## Run the Tests

+ Run all tests:
  ```bash
  forge test -vv
  ```
+ Run only the `BasicNft` tests:
  ```bash
  forge test --match-contract BasicNftTest -vv
  ```
+ Run only the `MoodNft` tests:
  ```bash
  forge test --match-contract MoodNftTest -vv
  ```

## Start a Local Blockchain

+ Run:
  ```bash
  anvil
  ```
+ Keep this terminal open.
+ Open another terminal for deployment and interaction commands.

## Deploy on Anvil

+ Deploy `BasicNft`:
  ```bash
  forge script script/DeployBasicNft.s.sol:DeployBasicNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Deploy `MoodNft`:
  ```bash
  forge script script/DeployMoodNft.s.sol:DeployMoodNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```

## Use the Makefile

+ This project includes a `Makefile` with shortcuts.
+ Common commands:
  ```bash
  make build
  make test
  make anvil
  make deploy
  make mint
  make deployMood
  make mintMoodNft
  make flipMoodNft TOKEN_ID=0
  ```
+ If you are on Windows, run these from `Git Bash`, not plain PowerShell.
+ The `install` target in the `Makefile` uses the same submodule-based dependency setup described above.

## Optional Environment Variables

+ If you want to deploy `BasicNft` with your own IPFS metadata folder:
  ```bash
  export IPFS_BASE_TOKEN_URI=ipfs://<YOUR_METADATA_FOLDER_CID>/
  ```
+ If you want to flip a specific `MoodNft` token:
  ```bash
  export TOKEN_ID=0
  ```

## Deploying Beyond Anvil

+ The core exercises in this repository are designed for local development on `anvil`.
+ After you finish the local workflow, you can move to a public testnet such as `Sepolia`.
+ The contract code and Foundry scripts are already compatible with this transition.
+ What changes is the environment configuration:
  + a public RPC endpoint
  + a real wallet private key
  + test ETH for gas
  + optional block explorer verification settings

## Required `.env` Values for Sepolia

+ To use the Sepolia targets in the `Makefile`, create a local `.env` file in the project root.
+ Typical values are:
  ```bash
  SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/<YOUR_KEY>
  PRIVATE_KEY=<YOUR_WALLET_PRIVATE_KEY>
  ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
  IPFS_BASE_TOKEN_URI=ipfs://<YOUR_METADATA_FOLDER_CID>/
  ```
+ `SEPOLIA_RPC_URL`
+ your Sepolia RPC endpoint from Alchemy, Infura, or another provider
+ `PRIVATE_KEY`
+ the wallet that will pay for deployment and minting gas
+ `ETHERSCAN_API_KEY`
+ used by the `--verify` flag in the Makefile's Sepolia commands
+ `IPFS_BASE_TOKEN_URI`
+ optional for `BasicNft`, but useful if you want your deployment to point to your own metadata folder immediately
+ Do not commit real RPC keys, private keys, or explorer API keys to GitHub.

## Funding a Sepolia Wallet

+ Before deploying to Sepolia, the wallet behind `PRIVATE_KEY` must hold Sepolia ETH.
+ You can get test ETH from a Sepolia faucet.
+ Without test ETH, deployment and mint transactions will fail even if the RPC and private key are correct.

## Sepolia with the Makefile

+ `Makefile` already includes Sepolia-ready commands.
+ For `BasicNft`, you can use the dedicated targets:
  ```bash
  make deploy-sepolia
  make mint-sepolia
  ```
+ These targets use:
+ `SEPOLIA_RPC_URL`
+ `PRIVATE_KEY`
+ `ETHERSCAN_API_KEY`
+ If you want to deploy `BasicNft` with a custom metadata folder, make sure `IPFS_BASE_TOKEN_URI` is already set in `.env`.

## Using `ARGS="--network sepolia"`

+ Some targets reuse the shared `NETWORK_ARGS` variable.
+ You can switch them from `anvil` to `sepolia` by passing:
  ```bash
  ARGS="--network sepolia"
  ```
+ Examples:
  ```bash
  make deploy ARGS="--network sepolia"
  make mint ARGS="--network sepolia"
  make deployMood ARGS="--network sepolia"
  make mintMoodNft ARGS="--network sepolia"
  make flipMoodNft TOKEN_ID=0 ARGS="--network sepolia"
  make update-base-uri NEW_IPFS_BASE_TOKEN_URI=ipfs://<NEW_FOLDER_CID>/ ARGS="--network sepolia"
  ```
+ This is useful because it gives one consistent pattern for both local and testnet execution.
