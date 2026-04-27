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

## Common Problems
+ `make: command not found`
+ Use Git Bash on Windows.
+ `node: command not found`
+ This is fine for this project unless you add frontend tooling later.
+ `solc: command not found`
+ This is also fine. Foundry manages the compiler for you.
+ `submodule not found` or import errors from `lib/...`
+ Run:
  ```bash
  git submodule update --init --recursive
  ```
+ `forge install` changed the contents of your `lib/` folder unexpectedly
+ Re-sync the repository dependencies with:
+   ```bash
+   git submodule update --init --recursive
+   ```
+ `TOKEN_ID not found`
+ Pass it explicitly:
  ```bash
  make flipMoodNft TOKEN_ID=0
  ```

## Next Step
+ After setup, continue with:
+ [Exercise 5](./5_Exercise5.md)
+ [Exercise 6](./6_Exercise6.md)
