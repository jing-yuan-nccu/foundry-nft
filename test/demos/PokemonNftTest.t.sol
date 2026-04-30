// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {PokemonNft} from "src/demos/PokemonNft.sol";

contract PokemonNftTest is Test {
    PokemonNft private pokemonNft;

    uint256 private constant TEEN_AGE = 60;
    uint256 private constant ADULT_AGE = 180;

    string private constant SQUIRTLE_BABY = "http://localhost:5173/pokemon/metadata/squirtle-baby.json";
    string private constant SQUIRTLE_TEEN = "http://localhost:5173/pokemon/metadata/squirtle-teen.json";
    string private constant SQUIRTLE_ADULT = "http://localhost:5173/pokemon/metadata/squirtle-adult.json";
    string private constant CHARMANDER_BABY = "http://localhost:5173/pokemon/metadata/charmander-baby.json";
    string private constant CHARMANDER_TEEN = "http://localhost:5173/pokemon/metadata/charmander-teen.json";
    string private constant CHARMANDER_ADULT = "http://localhost:5173/pokemon/metadata/charmander-adult.json";
    string private constant BULBASAUR_BABY = "http://localhost:5173/pokemon/metadata/bulbasaur-baby.json";
    string private constant BULBASAUR_TEEN = "http://localhost:5173/pokemon/metadata/bulbasaur-teen.json";
    string private constant BULBASAUR_ADULT = "http://localhost:5173/pokemon/metadata/bulbasaur-adult.json";

    address private USER = makeAddr("user");

    function setUp() public {
        pokemonNft = new PokemonNft(TEEN_AGE, ADULT_AGE, _tokenUris());
    }

    function testNameAndSymbolAreCorrect() public view {
        assertEq(pokemonNft.name(), "Pokemon Growth Gacha");
        assertEq(pokemonNft.symbol(), "PGG");
    }

    function testCanMintPokemon() public {
        vm.prank(USER);
        pokemonNft.mintNft();

        assertEq(pokemonNft.balanceOf(USER), 1);
        assertEq(pokemonNft.ownerOf(0), USER);
        assertEq(pokemonNft.getTokenCounter(), 1);
    }

    function testPokemonStartsAsBaby() public {
        vm.prank(USER);
        pokemonNft.mintNft();

        assertEq(uint256(pokemonNft.getStage(0)), uint256(PokemonNft.Stage.Baby));
    }

    function testPokemonGrowsOverTime() public {
        vm.prank(USER);
        pokemonNft.mintNft();

        vm.warp(block.timestamp + TEEN_AGE);
        assertEq(uint256(pokemonNft.getStage(0)), uint256(PokemonNft.Stage.Teen));

        vm.warp(block.timestamp + (ADULT_AGE - TEEN_AGE));
        assertEq(uint256(pokemonNft.getStage(0)), uint256(PokemonNft.Stage.Adult));
    }

    function testTokenUriChangesWhenPokemonGrows() public {
        vm.warp(100);
        vm.prank(USER);
        pokemonNft.mintNft();

        (PokemonNft.Species species,,,) = pokemonNft.getPokemon(0);

        assertEq(pokemonNft.tokenURI(0), _expectedUri(species, PokemonNft.Stage.Baby));

        vm.warp(100 + TEEN_AGE);
        assertEq(pokemonNft.tokenURI(0), _expectedUri(species, PokemonNft.Stage.Teen));

        vm.warp(100 + ADULT_AGE);
        assertEq(pokemonNft.tokenURI(0), _expectedUri(species, PokemonNft.Stage.Adult));
    }

    function testTimeUntilNextStageCountsDown() public {
        vm.warp(100);
        vm.prank(USER);
        pokemonNft.mintNft();

        assertEq(pokemonNft.getTimeUntilNextStage(0), TEEN_AGE);

        vm.warp(130);
        assertEq(pokemonNft.getTimeUntilNextStage(0), TEEN_AGE - 30);

        vm.warp(100 + TEEN_AGE);
        assertEq(pokemonNft.getTimeUntilNextStage(0), ADULT_AGE - TEEN_AGE);

        vm.warp(100 + ADULT_AGE);
        assertEq(pokemonNft.getTimeUntilNextStage(0), 0);
    }

    function testRefreshMetadataEmitsErc4906Event() public {
        vm.prank(USER);
        pokemonNft.mintNft();

        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(0);
        pokemonNft.refreshMetadata(0);
    }

    function testSupportsErc4906Interface() public view {
        assertTrue(pokemonNft.supportsInterface(type(IERC4906).interfaceId));
    }

    function testConstructorRevertsIfAdultAgeIsNotGreaterThanTeenAge() public {
        vm.expectRevert(PokemonNft.PokemonNft__AdultAgeMustBeGreaterThanTeenAge.selector);
        new PokemonNft(ADULT_AGE, TEEN_AGE, _tokenUris());
    }

    function _tokenUris() private pure returns (string[9] memory) {
        return [
            SQUIRTLE_BABY,
            SQUIRTLE_TEEN,
            SQUIRTLE_ADULT,
            CHARMANDER_BABY,
            CHARMANDER_TEEN,
            CHARMANDER_ADULT,
            BULBASAUR_BABY,
            BULBASAUR_TEEN,
            BULBASAUR_ADULT
        ];
    }

    function _expectedUri(PokemonNft.Species species, PokemonNft.Stage stage) private pure returns (string memory) {
        string[9] memory uris = _tokenUris();
        return uris[(uint256(species) * 3) + uint256(stage)];
    }
}
