# Exercise 5: Basic ERC-721 NFT

This exercise is designed as a continuation of the materials in:

+ [QuPepe/blockchain](https://github.com/QuPepe/blockchain)

It should be studied after:

+ `Exercise 4: Create Your Own Tokens`
+ `lecture/ERC-721_Tokens.md`
+ `lecture/ERC20_vs_ERC721_Comparison.md`

## Goal
+ Build and test a basic ERC-721 NFT contract with Foundry.
+ Deploy the contract on `anvil`.
+ Mint NFTs and inspect their metadata with `cast`.

## Create, Test, and Deploy the BasicNft Contract on Anvil
+ Open a Git Bash (in Windows) or a terminal (in Mac).
+ Clone this repository and enter the folder.
  ```
  git clone https://github.com/jing-yuan-nccu/foundry-nft.git
  cd foundry-nft
  ```
+ Initialize the dependencies.
  ```
  git submodule update --init --recursive
  ```
+ Open Visual Studio Code.
  ```
  code .
  ```
+ Examine the contract file `src/BasicNft.sol`.
+ Examine the deployment script `script/DeployBasicNft.s.sol`.
+ Examine the interaction script `script/Interactions.s.sol`.
+ Examine the test file `test/BasicNftTest.t.sol`.
+ Build the project.
  ```
  forge build
  ```
+ Run the `BasicNft` tests.
  ```
  forge test --match-contract BasicNftTest -vv
  ```
+ Start a local blockchain.
  ```
  anvil
  ```
+ Open another Git Bash or terminal in the same project folder.
+ Deploy the contract using the deployment script.
  ```
  forge script script/DeployBasicNft.s.sol:DeployBasicNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
  ```
  make deploy
  ```

## Interact with the BasicNft Contract on Anvil
+ Mint one NFT with the interaction script.
  ```
  forge script script/Interactions.s.sol:MintBasicNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
  ```
  make mint
  ```
+ Set your deployed contract address as an environment variable.
  ```
  export CONTRACT_ADDRESS=<YOUR_BASIC_NFT_CONTRACT_ADDRESS>
  ```
+ Query the NFT name.
  ```
  cast call $CONTRACT_ADDRESS "name()(string)" --rpc-url http://127.0.0.1:8545
  ```
+ Query the NFT symbol.
  ```
  cast call $CONTRACT_ADDRESS "symbol()(string)" --rpc-url http://127.0.0.1:8545
  ```
+ Query the owner of token `0`.
  ```
  cast call $CONTRACT_ADDRESS "ownerOf(uint256)(address)" 0 --rpc-url http://127.0.0.1:8545
  ```
+ Query the token URI of token `0`.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
  ```
+ Mint another NFT directly with `cast send`.
  ```
  cast send $CONTRACT_ADDRESS "mintNft()" --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  ```
+ Query the owner of token `1`.
  ```
  cast call $CONTRACT_ADDRESS "ownerOf(uint256)(address)" 1 --rpc-url http://127.0.0.1:8545
  ```
+ Query the token URI of token `1`.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 1 --rpc-url http://127.0.0.1:8545
  ```

## What to Observe
+ `BasicNft` uses the ERC-721 standard, so ownership is tracked by `tokenId`.
+ The metadata URI is built from a base URI plus the token id.
+ This contract uses a static metadata pattern:
  ```
  <baseURI><tokenId>.json
  ```
+ Token `0` and token `1` are different NFTs even though they are minted from the same contract.

## Think
+ Why does ERC-721 use `ownerOf(tokenId)` instead of tracking balances only?
+ Why is `tokenURI()` important for wallets and marketplaces?
+ How is `BasicNft` different from the ERC-20 contract in the teacher's `Exercise 4`?
