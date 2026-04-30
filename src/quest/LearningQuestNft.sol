// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {LearningQuest} from "src/quest/LearningQuest.sol";

contract LearningQuestNft is ERC721, IERC4906 {
    uint256 private constant STAGE_URI_COUNT = 4;

    uint256 private s_tokenCounter;
    LearningQuest private immutable i_quest;

    mapping(uint256 tokenId => address student) private s_tokenIdToStudent;
    mapping(address student => uint256 tokenId) private s_studentToTokenId;
    mapping(address student => bool minted) private s_hasMinted;
    mapping(uint256 stage => string uri) private s_stageUris;

    error LearningQuestNft__AlreadyMinted();
    error LearningQuestNft__InvalidQuest();

    event QuestCardMinted(address indexed student, uint256 indexed tokenId);

    constructor(address quest, string[4] memory stageUris) ERC721("Sepolia Quest Card", "SQC") {
        if (quest == address(0)) {
            revert LearningQuestNft__InvalidQuest();
        }
        i_quest = LearningQuest(quest);

        for (uint256 stage = 0; stage < STAGE_URI_COUNT; stage++) {
            s_stageUris[stage] = stageUris[stage];
        }
    }

    function mintQuestCard() external {
        if (s_hasMinted[msg.sender]) {
            revert LearningQuestNft__AlreadyMinted();
        }

        uint256 tokenId = s_tokenCounter;
        s_tokenCounter++;
        s_hasMinted[msg.sender] = true;
        s_tokenIdToStudent[tokenId] = msg.sender;
        s_studentToTokenId[msg.sender] = tokenId;

        _safeMint(msg.sender, tokenId);
        emit QuestCardMinted(msg.sender, tokenId);
    }

    function refreshMetadata(uint256 tokenId) external {
        _requireOwned(tokenId);
        emit MetadataUpdate(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        address student = s_tokenIdToStudent[tokenId];
        uint8 stage = i_quest.getHighestCompletedStage(student);
        return s_stageUris[stage];
    }

    function getQuest() external view returns (address) {
        return address(i_quest);
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }

    function getStudentForToken(uint256 tokenId) external view returns (address) {
        _requireOwned(tokenId);
        return s_tokenIdToStudent[tokenId];
    }

    function getTokenIdForStudent(address student) external view returns (uint256 tokenId, bool minted) {
        return (s_studentToTokenId[student], s_hasMinted[student]);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
    }
}
