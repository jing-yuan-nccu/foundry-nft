# Exercise 3: MoodNft

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

## Understand What MoodNft Does
+ `MoodNft` stores two SVG image URIs:
  - a happy image
  - a sad image
+ When `mintNft()` is called, the NFT starts in the `HAPPY` state.
+ When `flipMood(tokenId)` is called by the owner or an approved address, the NFT changes between `HAPPY` and `SAD`.
+ The metadata is fully onchain. The `tokenURI()` function returns a Base64-encoded JSON string.
+ The image field in that JSON is also an onchain Base64-encoded SVG.

## Notes
+ The SVG files used by this contract are:
  ```
  ./img/happy.svg
  ./img/sad.svg
  ```
+ If you change those SVG files and redeploy, the NFT metadata will also change.

