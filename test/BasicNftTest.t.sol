// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {BasicNft} from "src/BasicNft.sol";

contract BasicNftTest is Test {
    BasicNft private basicNft;

    string public constant BASE_TOKEN_URI = "ipfs://QmMetaDataFolder/";
    address public USER = makeAddr("user");

    function setUp() public {
        basicNft = new BasicNft(BASE_TOKEN_URI);
    }

    function testNftNameIsCorrect() public view {
        assertEq(basicNft.name(), "Charizard");
    }

    function testNftSymbolIsCorrect() public view {
        assertEq(basicNft.symbol(), "006");
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        basicNft.mintNft();

        assertEq(basicNft.balanceOf(USER), 1);
        assertEq(basicNft.ownerOf(0), USER);
        assertEq(basicNft.tokenURI(0), string.concat(BASE_TOKEN_URI, "0.json"));
    }
}
