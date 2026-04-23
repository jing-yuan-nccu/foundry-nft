// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BasicNft is ERC721 {
    uint256 private s_tokenCounter;
    string private s_baseTokenUri;

    constructor(string memory baseTokenUri) ERC721("Charizard", "006") {
        s_tokenCounter = 0;
        s_baseTokenUri = baseTokenUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(s_baseTokenUri, Strings.toString(tokenId), ".json");
    }
}
