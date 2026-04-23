# NFT Exercises on Anvil

This repository is organized as a step-by-step Foundry practice project for two NFT contracts:

+ `BasicNft`: a simple ERC-721 NFT with an IPFS-based metadata URI.
+ `MoodNft`: an onchain SVG NFT whose mood can be flipped between happy and sad.

All exercises in this repository are arranged for local development on `anvil`.

## Exercises
+ [Exercise 1: BasicNft Setup, Test, and Deploy](./1_Exercise1.md)
+ [Exercise 2: Interact with BasicNft on Anvil](./2_Exercise2.md)
+ [Exercise 3: MoodNft Setup, Test, and Deploy](./3_Exercise3.md)
+ [Exercise 4: Interact with MoodNft on Anvil](./4_Exercise4.md)
+ [Project Structure](./Structure.md)

## Software Used in This Exercise Set
+ Solidity: [Foundry](https://book.getfoundry.sh/)
+ Local blockchain: `anvil`
+ Command-line interaction: `cast`
+ Code editor: [Visual Studio Code](https://code.visualstudio.com/)

## Notes
+ The Makefile already includes commands for deploying and interacting with both NFT contracts.
+ The default local private key used in the examples is the first Anvil test key:
  ```
  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
  ```
+ If you restart `anvil`, you should redeploy the contracts before running mint or flip scripts again.

