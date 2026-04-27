# Exercise 6: Dynamic Onchain NFT

This exercise is designed as a continuation of the materials in:

+ [QuPepe/blockchain](https://github.com/QuPepe/blockchain)

It should be studied after:

+ `Exercise 5: Basic ERC-721 NFT`
+ [ERC-721_Tokens.md](https://github.com/QuPepe/blockchain/blob/main/lecture/ERC-721_Tokens.md) (in `QuPepe/blockchain`)
+ [ERC20_vs_ERC721_Comparison.md](https://github.com/QuPepe/blockchain/blob/main/lecture/ERC20_vs_ERC721_Comparison.md) (in `QuPepe/blockchain`)
+ [`lecture/Static_vs_Dynamic_NFTs.md`](./lecture/Static_vs_Dynamic_NFTs.md)
+ [`lecture/Onchain_NFT_Metadata.md`](./lecture/Onchain_NFT_Metadata.md)

## Goal
+ Build and test a dynamic NFT contract.
+ Deploy the contract on `anvil`.
+ Mint a `MoodNft` and flip its mood.
+ Observe how `tokenURI()` changes while `tokenId` stays the same.

## Create, Test, and Deploy the MoodNft Contract on Anvil
+ Open a Git Bash (in Windows) or a terminal (in Mac).
+ Enter this project folder.
  ```
  cd foundry-nft
  ```
+ Open Visual Studio Code.
  ```
  code .
  ```
+ Examine the contract file `src/MoodNft.sol`.
+ Examine the deployment script `script/DeployMoodNft.s.sol`.
+ Examine the interaction script `script/Interactions.s.sol`.
+ Examine the test file `test/MoodNftTest.t.sol`.
+ Build the project.
  ```
  forge build
  ```
+ Run the `MoodNft` tests.
  ```
  forge test --match-contract MoodNftTest -vv
  ```
+ Run only the flip-related test.
  ```
  forge test --match-test testFlipTokenToSad -vvvv
  ```
+ Start a local blockchain.
  ```
  anvil
  ```
+ Open another Git Bash or terminal in the same project folder.
+ Deploy the contract using the deployment script.
  ```
  forge script script/DeployMoodNft.s.sol:DeployMoodNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
  ```
  make deployMood
  ```

## Interact with the MoodNft Contract on Anvil
+ Mint one `MoodNft`.
  ```
  forge script script/Interactions.s.sol:MintMoodNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
  ```
  make mintMoodNft
  ```
+ Set your deployed `MoodNft` contract address as an environment variable.
  ```
  export CONTRACT_ADDRESS=<YOUR_MOOD_NFT_CONTRACT_ADDRESS>
  ```
+ Query the owner of token `0`.
  ```
  cast call $CONTRACT_ADDRESS "ownerOf(uint256)(address)" 0 --rpc-url http://127.0.0.1:8545
  ```
+ Query the token URI of token `0`.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
  ```
+ Flip the mood of token `0`.
  ```
  make flipMoodNft TOKEN_ID=0
  ```
+ Query the token URI of token `0` again.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
  ```
+ Flip the mood again.
  ```
  make flipMoodNft TOKEN_ID=0
  ```
+ Query the token URI one more time.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
  ```

## What to Observe
+ `MoodNft` starts in the `HAPPY` state when minted.
+ `flipMood(tokenId)` changes the state to `SAD`, and flipping again changes it back.
+ The token id does not change.
+ The owner does not change.
+ The metadata returned by `tokenURI()` does change.
+ This is an example of a dynamic NFT with onchain metadata.

## Verify with Tests
+ Run the mint and flip test again.
  ```
  forge test --match-test testFlipTokenToSad -vvvv
  ```
+ Run all tests for `MoodNft`.
  ```
  forge test --match-contract MoodNftTest -vv
  ```

## Think
+ Why is owner or approval checking required in `flipMood(uint256 tokenId)`?
+ Why can a single NFT have changing metadata?
+ What is the difference between IPFS-hosted metadata and Base64 onchain metadata?
