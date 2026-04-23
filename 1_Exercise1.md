# Exercise 1: BasicNft

## Create, Test, and Deploy the BasicNft Contract on Anvil
+ Open a Git Bash (in Windows) or a terminal (in Mac).
+ Enter this project folder.
  ```
  cd foundry-nft
  ```
+ Open Visual Studio Code.
  ```
  code .
  ```
+ Examine the contract file `src/BasicNft.sol`.
+ Examine the deployment script `script/DeployBasicNft.s.sol`.
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

## Understand What BasicNft Does
+ The NFT name is `Charizard`.
+ The NFT symbol is `006`.
+ Each time `mintNft()` is called, one new NFT is minted to `msg.sender`.
+ The token URI is built from the base URI plus the token id:
  ```
  <baseURI><tokenId>.json
  ```
+ In this project, the default base URI in the deployment script is:
  ```
  ipfs://YOUR_METADATA_FOLDER_CID/
  ```
+ So token `0` will resolve to:
  ```
  ipfs://YOUR_METADATA_FOLDER_CID/0.json
  ```

## Notes
+ If you want to use your own IPFS metadata folder, set the environment variable first:
  ```
  export IPFS_BASE_TOKEN_URI=ipfs://<YOUR_METADATA_FOLDER_CID>/
  ```
+ Then run the deployment script again.
+ The metadata example files used in this repository are in the `img` folder.

