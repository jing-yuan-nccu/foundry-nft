This repository is intended to serve as a continuation of the `QuPepe/blockchain` teaching materials.

After completing the NFT continuation exercises, the main files in this project will be used like this:

# Contracts
+ `/src/BasicNft.sol`: A basic ERC-721 NFT using an IPFS base token URI.
+ `/src/MoodNft.sol`: An ERC-721 NFT with onchain SVG metadata and a flip-able mood state.

# Scripts
+ `/script/DeployBasicNft.s.sol`: Deploy the `BasicNft` contract.
+ `/script/DeployMoodNft.s.sol`: Deploy the `MoodNft` contract.
+ `/script/Interactions.s.sol`: Mint `BasicNft`, mint `MoodNft`, and flip a `MoodNft`.

# Tests
+ `/test/BasicNftTest.t.sol`: Tests for `BasicNft`.
+ `/test/MoodNftTest.t.sol`: Tests for `MoodNft`.

# Assets
+ `/img/0.json`, `/img/1.json`, `/img/2.json`: Example metadata files for `BasicNft`.
+ `/img/happy.svg`, `/img/sad.svg`: SVG images used by `MoodNft`.

# Exercises
+ `/5_Exercise5.md`: Build, test, deploy, mint, and inspect `BasicNft`.
+ `/6_Exercise6.md`: Build, test, deploy, mint, and flip `MoodNft`.

# Lecture Notes
+ `/lecture/NFT_Metadata_and_IPFS.md`: Introduces NFT metadata and IPFS-based storage.
+ `/lecture/Onchain_NFT_Metadata.md`: Explains onchain metadata and Base64-encoded NFT responses.
+ `/lecture/Static_vs_Dynamic_NFTs.md`: Compares static NFTs and dynamic NFTs.
