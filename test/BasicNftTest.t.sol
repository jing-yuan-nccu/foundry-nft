// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {BasicNft} from "src/BasicNft.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";

contract BasicNftTest is Test {
    BasicNft private basicNft;

    string public constant BASE_TOKEN_URI = "ipfs://QmMetaDataFolder/";
    string public constant UPDATED_BASE_TOKEN_URI = "ipfs://QmUpdatedMetaDataFolder/";
    address public USER = makeAddr("user");

    function setUp() public {
        basicNft = new BasicNft(BASE_TOKEN_URI);
    }

    function testNftNameIsCorrect() public view {
        assertEq(basicNft.name(), "Pokemon Collection");
    }

    function testNftSymbolIsCorrect() public view {
        assertEq(basicNft.symbol(), "PKMN");
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        basicNft.mintNft();

        assertEq(basicNft.balanceOf(USER), 1);
        assertEq(basicNft.ownerOf(0), USER);
        assertEq(basicNft.tokenURI(0), string.concat(BASE_TOKEN_URI, "0.json"));
    }

    function testOwnerCanUpdateBaseTokenUri() public {
        vm.expectEmit(true, true, true, true);
        emit IERC4906.BatchMetadataUpdate(0, type(uint256).max);
        basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);

        assertEq(basicNft.baseTokenUri(), UPDATED_BASE_TOKEN_URI);
    }

    function testNonOwnerCannotUpdateBaseTokenUri() public {
        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);
    }

    function testTokenUriUsesUpdatedBaseTokenUri() public {
        vm.prank(USER);
        basicNft.mintNft();

        basicNft.setBaseTokenUri(UPDATED_BASE_TOKEN_URI);

        assertEq(basicNft.tokenURI(0), string.concat(UPDATED_BASE_TOKEN_URI, "0.json"));
    }

    function testSupportsErc4906Interface() public view {
        assertTrue(basicNft.supportsInterface(type(IERC4906).interfaceId));
    }
}
