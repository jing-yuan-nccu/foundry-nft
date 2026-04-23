// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721, Ownable {
    enum NFTState {
        HAPPY,
        SAD
    }

    uint256 private s_tokenCounter;
    string private s_sadSvgUri;
    string private s_happySvgUri;
    mapping(uint256 => NFTState) private s_tokenIdToState;

    error MoodNft__CantFlipMoodIfNotOwner();

    constructor(string memory sadUri, string memory happyUri)
        ERC721("Mood NFT", "MN")
        Ownable(msg.sender)
    {
        s_sadSvgUri = sadUri;
        s_happySvgUri = happyUri;
    }

    function mintNft() public {
        s_tokenIdToState[s_tokenCounter] = NFTState.HAPPY;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function flipMood(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && msg.sender != getApproved(tokenId) && !isApprovedForAll(owner, msg.sender)) {
            revert MoodNft__CantFlipMoodIfNotOwner();
        }

        if (s_tokenIdToState[tokenId] == NFTState.HAPPY) {
            s_tokenIdToState[tokenId] = NFTState.SAD;
        } else {
            s_tokenIdToState[tokenId] = NFTState.HAPPY;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory imageURI = s_tokenIdToState[tokenId] == NFTState.HAPPY ? s_happySvgUri : s_sadSvgUri;

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '",',
                            '"description":"An NFT that reflects mood.",',
                            '"attributes":[{"trait_type":"moodiness","value":100}],',
                            '"image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }
}
