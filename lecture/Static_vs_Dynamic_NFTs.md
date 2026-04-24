# Static vs. Dynamic NFTs

## Introduction

Not all NFTs behave the same way after minting.

Some NFTs always keep the same metadata. Others can change their appearance or metadata over time.

This gives us two useful categories:

+ static NFTs
+ dynamic NFTs

---

## Static NFTs

A static NFT keeps the same metadata after minting.

Typical pattern:

+ `tokenURI(tokenId)` always points to the same metadata file
+ the image and attributes do not change

Common examples:

+ profile picture collections
+ certificates
+ event tickets
+ fixed digital art

---

## Dynamic NFTs

A dynamic NFT can change its metadata after minting.

Typical pattern:

+ `tokenURI(tokenId)` depends on some changing state
+ image, attributes, or description may update

Common examples:

+ game characters
+ evolving art
+ achievement badges
+ mood-based or state-based NFTs

---

## Comparison

| Feature | Static NFT | Dynamic NFT |
|---|---|---|
| Metadata after mint | fixed | can change |
| Complexity | lower | higher |
| Common storage | IPFS / server | IPFS or onchain |
| Good for | fixed collectibles | interactive assets |

---

## Examples in This Repository

### BasicNft

`BasicNft` is a static NFT example.

+ It builds a token URI from a base URI and token id
+ Each token points to a metadata file
+ The metadata is intended to stay fixed

### MoodNft

`MoodNft` is a dynamic NFT example.

+ It stores a mood state for each token
+ `flipMood(tokenId)` changes that state
+ `tokenURI(tokenId)` changes based on that state

---

## Why This Comparison Matters

Students often first learn ERC-20, then basic ERC-721. A static vs. dynamic NFT comparison helps them see that:

+ ERC-721 is not only about ownership
+ metadata design is an important architectural decision
+ NFT behavior can be simple or interactive

---

## Connection to the Exercises

+ `Exercise 5` introduces a static NFT
+ `Exercise 6` introduces a dynamic onchain NFT
