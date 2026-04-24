# NFT Metadata and IPFS

## Introduction

An NFT is not only ownership data onchain. In practice, an NFT usually also needs metadata so that wallets and marketplaces can display:

+ name
+ description
+ image
+ attributes

This metadata is commonly returned through the ERC-721 `tokenURI()` function.

---

## What `tokenURI()` Returns

For many ERC-721 contracts, `tokenURI(tokenId)` returns a URI pointing to a JSON file.

Example:

```text
ipfs://QmExampleMetadataFolder/0.json
```

That JSON file may look like:

```json
{
  "name": "Charizard #0",
  "description": "A basic NFT",
  "image": "ipfs://QmExampleImageFolder/charizard.png"
}
```

---

## Why Metadata Matters

Without metadata, an NFT is only a token id and an owner. Wallets and marketplaces need metadata to display the NFT in a human-friendly way.

Metadata makes the NFT meaningful.

---

## Why IPFS Is Commonly Used

IPFS is often used to store NFT metadata and media files because:

+ it is content-addressed
+ it is more decentralized than a normal web server
+ it is commonly supported in NFT projects

Instead of using:

```text
https://myserver.com/nft/0.json
```

many projects prefer:

```text
ipfs://Qm.../0.json
```

---

## BasicNft in This Project

The `BasicNft` contract in this repository uses a static metadata pattern:

```text
<baseURI><tokenId>.json
```

For example:

```text
ipfs://YOUR_METADATA_FOLDER_CID/0.json
```

This is a common beginner-friendly NFT design.

---

## Advantages of This Approach

+ Simple to understand
+ Easy to test
+ Easy to integrate with marketplaces
+ Good for art collections and fixed NFT sets

---

## Limitations

+ Metadata is usually fixed after publishing
+ If the referenced assets are not stored carefully, they may disappear
+ It is less suitable for NFTs whose state changes over time

---

## Connection to the Exercises

+ `Exercise 5` uses this model through `BasicNft`
+ `Exercise 6` will contrast this with an onchain dynamic metadata model
