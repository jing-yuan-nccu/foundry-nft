# Onchain NFT Metadata

## Introduction

Some NFTs do not store metadata on IPFS or a web server. Instead, they generate metadata directly onchain inside the smart contract.

In this model, `tokenURI()` returns the metadata itself, often encoded in Base64.

---

## Typical Structure

An onchain NFT may return:

+ Base64-encoded JSON metadata
+ an image field containing a Base64-encoded SVG

That means:

+ the metadata lives onchain
+ the image can also live onchain

---

## Why Projects Use Onchain Metadata

+ stronger immutability
+ fewer external dependencies
+ interesting generative or dynamic behavior
+ a stronger "fully onchain" identity

---

## Example Idea

Instead of returning:

```text
ipfs://Qm.../0.json
```

the contract may return:

```text
data:application/json;base64,...
```

and inside that JSON:

```text
data:image/svg+xml;base64,...
```

---

## MoodNft in This Project

The `MoodNft` contract in this repository uses onchain metadata.

It stores:

+ a happy SVG image URI
+ a sad SVG image URI

When `tokenURI(tokenId)` is called, the contract generates JSON metadata based on the current mood of the NFT.

---

## Advantages

+ no external metadata server required
+ no external image hosting required
+ metadata can react to contract state
+ useful for dynamic NFTs

---

## Tradeoffs

+ more complicated than static IPFS metadata
+ can cost more gas
+ may be harder for beginners to read at first

---

## Connection to the Exercises

+ `Exercise 5` uses static metadata with `BasicNft`
+ `Exercise 6` uses onchain dynamic metadata with `MoodNft`
