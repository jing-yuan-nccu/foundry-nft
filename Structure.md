This repository is organized as a continuation of the `QuPepe/blockchain` teaching materials.

# Tracks
+ `exercises`: required Anvil NFT lessons.
+ `demos`: optional local game-style prototypes.
+ `quest`: optional Sepolia learning quest extension.

# Contracts
+ `/src/exercises/BasicNft.sol`: A basic ERC-721 NFT using an IPFS base token URI.
+ `/src/exercises/MoodNft.sol`: An ERC-721 NFT with onchain SVG metadata and a flip-able mood state.
+ `/src/demos/PokemonNft.sol`: A local growth gacha NFT demo.
+ `/src/quest/LearningQuest.sol`: Tracks verified Sepolia challenge completion.
+ `/src/quest/LearningQuestNft.sol`: A quest card NFT that evolves based on `LearningQuest` progress.

# Scripts
+ `/script/exercises/DeployBasicNft.s.sol`: Deploy the `BasicNft` contract.
+ `/script/exercises/DeployMoodNft.s.sol`: Deploy the `MoodNft` contract.
+ `/script/exercises/Interactions.s.sol`: Mint `BasicNft`, mint `MoodNft`, and flip a `MoodNft`.
+ `/script/demos/DeployPokemonNft.s.sol`: Deploy the Pokemon growth demo.
+ `/script/quest/DeployLearningQuest.s.sol`: Deploy the Sepolia quest tracker and quest card NFT.

# Tests
+ `/test/exercises/BasicNftTest.t.sol`: Tests for `BasicNft`.
+ `/test/exercises/MoodNftTest.t.sol`: Tests for `MoodNft`.
+ `/test/demos/PokemonNftTest.t.sol`: Tests for the Pokemon growth demo.
+ `/test/quest/LearningQuestTest.t.sol`: Tests for the Sepolia quest contracts.

# Assets
+ `/img/0.json` to `/img/9.json`: Example metadata files for `BasicNft`.
+ `/img/happy.svg`, `/img/sad.svg`: SVG images used by `MoodNft`.
+ `/frontend/pokemon/assets`: SVGs for the Pokemon demo.
+ `/frontend/pokemon/metadata`: Metadata JSON for the Pokemon demo.
+ `/frontend/quest/assets`: SVGs for Sepolia quest cards.
+ `/frontend/quest/metadata`: Metadata JSON for Sepolia quest cards.

# Exercises
+ `/5_Exercise5.md`: Build, test, deploy, mint, and inspect `BasicNft`.
+ `/6_Exercise6.md`: Build, test, deploy, mint, and flip `MoodNft`.

# Lecture Notes
+ `/lecture/NFT_Metadata_and_IPFS.md`: Introduces NFT metadata and IPFS-based storage.
+ `/lecture/Onchain_NFT_Metadata.md`: Explains onchain metadata and Base64-encoded NFT responses.
+ `/lecture/Static_vs_Dynamic_NFTs.md`: Compares static NFTs and dynamic NFTs.
+ `/lecture/ERC165_and_ERC4906.md`: Explains interface detection and metadata update signaling for NFTs.
