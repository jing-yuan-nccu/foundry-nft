# Exercise 4: Interact with MoodNft

## Mint and Flip MoodNft on Anvil
+ Make sure `anvil` is already running.
+ Make sure you have already deployed `MoodNft`.
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
+ Flip the mood of token `0` with the interaction script.
  ```
  TOKEN_ID=0 forge script script/Interactions.s.sol:FlipMoodNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
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
+ Query the token URI of token `0` one more time.
  ```
  cast call $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url http://127.0.0.1:8545
  ```

## Verify with Tests
+ Run the mint and flip test again.
  ```
  forge test --match-test testFlipTokenToSad -vvvv
  ```
+ Run all tests for `MoodNft`.
  ```
  forge test --match-contract MoodNftTest -vv
  ```

## Notes
+ `TOKEN_ID=0` means you are operating on the first NFT minted by that contract.
+ If you redeploy a new `MoodNft` contract, the first minted NFT will again usually be token `0`.
+ If the onchain data has changed but a wallet UI does not update immediately, it may be showing cached NFT metadata.

## Think
+ Why is the owner check necessary in `flipMood(uint256 tokenId)`?
+ Why does the token URI change even though the token id remains the same?
