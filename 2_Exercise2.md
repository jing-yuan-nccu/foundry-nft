# Exercise 2: Interact with BasicNft

## Mint and Inspect BasicNft on Anvil
+ Make sure `anvil` is already running.
+ Make sure you have already deployed `BasicNft`.
+ Mint one NFT with the interaction script.
  ```
  forge script script/Interactions.s.sol:MintBasicNft --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
  ```
+ Alternatively, use the Makefile target.
  ```
  make mint
  ```
+ Look at the latest broadcast result:
  ```
  cat broadcast/Interactions.s.sol/31337/run-latest.json
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

## Think
+ Why does token `0` exist after the first mint, while token `1` exists only after the second mint?
+ Why does the contract not store a full token URI for each token, but instead build it from a base URI and token id?

