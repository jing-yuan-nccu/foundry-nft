// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract PokemonNft is ERC721, IERC4906 {
    enum Species {
        Squirtle,
        Charmander,
        Bulbasaur
    }

    enum Stage {
        Baby,
        Teen,
        Adult
    }

    struct Pokemon {
        Species species;
        uint64 birthTime;
    }

    uint256 private constant SPECIES_COUNT = 3;
    uint256 private constant STAGE_COUNT = 3;

    uint256 private s_tokenCounter;
    uint256 private immutable i_teenAge;
    uint256 private immutable i_adultAge;

    mapping(uint256 tokenId => Pokemon pokemon) private s_pokemons;
    mapping(uint256 species => mapping(uint256 stage => string uri)) private s_tokenUris;

    error PokemonNft__AdultAgeMustBeGreaterThanTeenAge();

    event PokemonMinted(address indexed owner, uint256 indexed tokenId, Species species);

    constructor(uint256 teenAge, uint256 adultAge, string[9] memory tokenUris)
        ERC721("Pokemon Growth Gacha", "PGG")
    {
        if (adultAge <= teenAge) {
            revert PokemonNft__AdultAgeMustBeGreaterThanTeenAge();
        }

        i_teenAge = teenAge;
        i_adultAge = adultAge;

        for (uint256 species = 0; species < SPECIES_COUNT; species++) {
            for (uint256 stage = 0; stage < STAGE_COUNT; stage++) {
                s_tokenUris[species][stage] = tokenUris[(species * STAGE_COUNT) + stage];
            }
        }
    }

    function mintNft() external {
        uint256 tokenId = s_tokenCounter;
        Species species = _drawSpecies(tokenId, msg.sender);

        s_pokemons[tokenId] = Pokemon({species: species, birthTime: uint64(block.timestamp)});
        s_tokenCounter++;

        _safeMint(msg.sender, tokenId);
        emit PokemonMinted(msg.sender, tokenId, species);
    }

    function refreshMetadata(uint256 tokenId) external {
        _requireOwned(tokenId);
        emit MetadataUpdate(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        Pokemon memory pokemon = s_pokemons[tokenId];
        Stage stage = getStage(tokenId);

        return s_tokenUris[uint256(pokemon.species)][uint256(stage)];
    }

    function getStage(uint256 tokenId) public view returns (Stage) {
        _requireOwned(tokenId);

        uint256 age = block.timestamp - s_pokemons[tokenId].birthTime;

        if (age >= i_adultAge) {
            return Stage.Adult;
        }
        if (age >= i_teenAge) {
            return Stage.Teen;
        }
        return Stage.Baby;
    }

    function getPokemon(uint256 tokenId)
        external
        view
        returns (Species species, Stage stage, uint256 birthTime, uint256 age)
    {
        _requireOwned(tokenId);

        Pokemon memory pokemon = s_pokemons[tokenId];
        species = pokemon.species;
        stage = getStage(tokenId);
        birthTime = pokemon.birthTime;
        age = block.timestamp - pokemon.birthTime;
    }

    function getTimeUntilNextStage(uint256 tokenId) external view returns (uint256) {
        _requireOwned(tokenId);

        uint256 age = block.timestamp - s_pokemons[tokenId].birthTime;

        if (age < i_teenAge) {
            return i_teenAge - age;
        }
        if (age < i_adultAge) {
            return i_adultAge - age;
        }
        return 0;
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getGrowthAges() external view returns (uint256 teenAge, uint256 adultAge) {
        return (i_teenAge, i_adultAge);
    }

    function getSpeciesName(Species species) external pure returns (string memory) {
        if (species == Species.Squirtle) {
            return "Squirtle";
        }
        if (species == Species.Charmander) {
            return "Charmander";
        }
        return "Bulbasaur";
    }

    function getStageName(Stage stage) external pure returns (string memory) {
        if (stage == Stage.Baby) {
            return "Baby";
        }
        if (stage == Stage.Teen) {
            return "Teen";
        }
        return "Adult";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
    }

    function _drawSpecies(uint256 tokenId, address minter) private view returns (Species) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, minter, tokenId))) % 100;

        if (random < 40) {
            return Species.Squirtle;
        }
        if (random < 80) {
            return Species.Charmander;
        }
        return Species.Bulbasaur;
    }
}
