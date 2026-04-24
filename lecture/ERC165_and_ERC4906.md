# ERC165 and ERC4906

## Introduction

When building NFTs, it is not enough for the contract to work onchain.

Wallets, marketplaces, and indexers also need a standard way to understand:

+ what interfaces the contract supports
+ whether NFT metadata has changed

This is where `ERC165` and `ERC4906` become useful.

---

## What ERC165 Is

`ERC165` is a standard interface detection mechanism.

It lets a contract answer this question:

+ "Do you support interface X?"

The standard way to ask is through:

```solidity
supportsInterface(bytes4 interfaceId)
```

This matters because external systems do not want to guess what a contract can do.

They want a standard way to check.

---

## Why ERC165 Matters for NFTs

Many important Ethereum standards are discoverable through `ERC165`.

For example:

+ `ERC721`
+ `ERC721Metadata`
+ `ERC4906`

If a marketplace or tool wants to know whether your NFT contract supports one of these standards, it can call `supportsInterface(...)`.

This makes integrations more reliable.

---

## What ERC4906 Is

`ERC4906` is a metadata update standard for NFTs.

It defines events that signal:

+ a specific token's metadata changed
+ a range of tokens' metadata changed

The two events are:

```solidity
event MetadataUpdate(uint256 _tokenId);
event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
```

These events are especially useful when metadata is not permanently fixed.

---

## Why ERC4906 Matters

Suppose your NFT contract updates its metadata by:

+ changing a base URI
+ revealing collection metadata later
+ switching from placeholder artwork to final artwork

Even if the contract now returns a new `tokenURI()`, marketplaces may not immediately know they should re-fetch metadata.

`ERC4906` gives them a standard signal that the metadata should be refreshed.

---

## Connection to This Project

In this repository, `BasicNft` originally used a static metadata pattern:

```text
<baseURI><tokenId>.json
```

That means a token URI could look like:

```text
ipfs://QmExampleFolder/0.json
```

Later, we added the ability for the owner to update the base URI.

Once metadata can change, it becomes useful to emit an `ERC4906` event so that external systems know the NFT metadata may need refreshing.

---

## How ERC165 and ERC4906 Work Together

`ERC4906` is not just an event convention.

It is also an interface that tools may want to detect.

That is why contracts commonly expose support for `ERC4906` through `ERC165`.

In practice:

+ `ERC165` answers "what standards do you support?"
+ `ERC4906` answers "has metadata changed?"

They solve different but related integration problems.

---

## Example from BasicNft

The updated `BasicNft` contract now includes:

+ `setBaseTokenUri(...)` so the owner can update the metadata folder
+ `baseTokenUri()` so the current base URI can be queried
+ `BatchMetadataUpdate(...)` so indexers can refresh metadata
+ `supportsInterface(...)` so tools can detect `ERC4906`

Conceptually, the flow is:

1. Upload new metadata to IPFS
2. Get the new folder CID
3. Update the contract base URI
4. Emit an `ERC4906` event
5. Let wallets and marketplaces refresh metadata

---

## Why This Was Needed

This project surfaced a very common beginner pain point:

+ changing files in an IPFS folder changes the folder CID
+ a deployed contract may still point to the old CID
+ marketplaces may keep showing cached metadata

Adding an owner-controlled base URI update solves the first contract-side problem.

Adding `ERC4906` helps solve the refresh-discovery problem.

---

## Tradeoffs

Using updateable metadata has benefits:

+ easier reveals
+ easier corrections
+ more flexibility for evolving collections

But it also introduces trust assumptions:

+ the owner can change what tokens point to
+ metadata is less "final" unless the project later freezes it

This is why many NFT projects start mutable and later freeze metadata.

---

## Summary

+ `ERC165` lets other systems detect what interfaces your contract supports
+ `ERC4906` lets your contract announce that NFT metadata changed
+ They are useful when your NFT metadata is updateable
+ In this project, they make `BasicNft` more practical for real metadata workflows

---

## Suggested Discussion Questions

+ Why is metadata refresh a separate problem from token ownership?
+ What are the trust tradeoffs of allowing `baseURI` updates?
+ When should a project prefer static metadata over updateable metadata?
+ Why might a marketplace still need manual refresh even if `ERC4906` is emitted?
