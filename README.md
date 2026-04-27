# NFT Module After QuPepe Blockchain Exercises

This repository is organized as a continuation module for the course materials in:

+ [QuPepe/blockchain](https://github.com/QuPepe/blockchain)

It is designed to follow the teacher's materials after the ERC-20 and ERC-721 introduction, and extends them with hands-on NFT implementation using Foundry.

This repository contains two NFT contracts:

+ `BasicNft`: a simple ERC-721 NFT with an IPFS-based metadata URI.
+ `MoodNft`: an onchain SVG NFT whose mood can be flipped between happy and sad.

All exercises in this repository are arranged for local development on `anvil`.

## Suggested Learning Order
+ Finish the core materials in [QuPepe/blockchain](https://github.com/QuPepe/blockchain)
+ Review the teacher's ERC-721 and ERC-20 vs. ERC-721 notes from the earlier `QuPepe/blockchain` materials
+ Read the NFT lecture notes in this repository
+ Complete `Exercise 5` and `Exercise 6`

## Setup and Exercises
+ [Setup](./Setup.md)
+ [Exercise 5: Basic ERC-721 NFT](./5_Exercise5.md)
+ [Exercise 6: Dynamic Onchain NFT](./6_Exercise6.md)
+ [Project Structure](./Structure.md)
+ After the local `anvil` exercises, you can extend the same scripts and Makefile flow to `Sepolia` using the environment variables described in [Setup](./Setup.md).

## Lecture Notes
+ [NFT Metadata and IPFS](./lecture/NFT_Metadata_and_IPFS.md)
+ [Onchain NFT Metadata](./lecture/Onchain_NFT_Metadata.md)
+ [Static vs. Dynamic NFTs](./lecture/Static_vs_Dynamic_NFTs.md)
+ [ERC165 and ERC4906](./lecture/ERC165_and_ERC4906.md)

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
