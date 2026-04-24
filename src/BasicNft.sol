// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BasicNft is ERC721, Ownable, IERC4906 {
    uint256 private s_tokenCounter;
    string private s_baseTokenUri;

    constructor(string memory initialBaseTokenUri) ERC721("Charizard", "006") Ownable(msg.sender) {
        s_tokenCounter = 0;
        s_baseTokenUri = initialBaseTokenUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(s_baseTokenUri, Strings.toString(tokenId), ".json");
    }

    function setBaseTokenUri(string memory newBaseTokenUri) public onlyOwner {
        s_baseTokenUri = newBaseTokenUri;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function baseTokenUri() public view returns (string memory) {
        return s_baseTokenUri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
    }
}
