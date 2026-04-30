// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {PokemonNft} from "src/demos/PokemonNft.sol";

contract DeployPokemonNft is Script {
    uint256 public constant DEFAULT_TEEN_AGE = 60;
    uint256 public constant DEFAULT_ADULT_AGE = 180;
    string public constant DEFAULT_METADATA_BASE_URI = "http://localhost:5173/pokemon/metadata/";

    function run() external returns (PokemonNft) {
        uint256 teenAge = vm.envOr("POKEMON_TEEN_AGE", DEFAULT_TEEN_AGE);
        uint256 adultAge = vm.envOr("POKEMON_ADULT_AGE", DEFAULT_ADULT_AGE);
        string memory metadataBaseUri = vm.envOr("POKEMON_METADATA_BASE_URI", DEFAULT_METADATA_BASE_URI);

        vm.startBroadcast();
        PokemonNft pokemonNft = new PokemonNft(teenAge, adultAge, _tokenUris(metadataBaseUri));
        vm.stopBroadcast();

        console2.log("PokemonNft deployed at:", address(pokemonNft));

        return pokemonNft;
    }

    function _tokenUris(string memory metadataBaseUri) private pure returns (string[9] memory) {
        return [
            string.concat(metadataBaseUri, "squirtle-baby.json"),
            string.concat(metadataBaseUri, "squirtle-teen.json"),
            string.concat(metadataBaseUri, "squirtle-adult.json"),
            string.concat(metadataBaseUri, "charmander-baby.json"),
            string.concat(metadataBaseUri, "charmander-teen.json"),
            string.concat(metadataBaseUri, "charmander-adult.json"),
            string.concat(metadataBaseUri, "bulbasaur-baby.json"),
            string.concat(metadataBaseUri, "bulbasaur-teen.json"),
            string.concat(metadataBaseUri, "bulbasaur-adult.json")
        ];
    }
}
