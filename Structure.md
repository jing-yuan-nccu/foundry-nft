After completing all exercises, the main files in this project will be used like this:

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
+ `/1_Exercise1.md`: Build, test, and deploy `BasicNft`.
+ `/2_Exercise2.md`: Mint and inspect `BasicNft` on Anvil.
+ `/3_Exercise3.md`: Build, test, and deploy `MoodNft`.
+ `/4_Exercise4.md`: Mint and flip `MoodNft` on Anvil.

