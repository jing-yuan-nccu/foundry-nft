// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {LearningQuest} from "src/quest/LearningQuest.sol";
import {LearningQuestNft} from "src/quest/LearningQuestNft.sol";

contract LearningQuestTest is Test {
    LearningQuest private quest;
    LearningQuestNft private questNft;

    uint8 private constant STAGE_ERC20 = 1;
    uint8 private constant STAGE_ERC721 = 2;
    uint8 private constant STAGE_ONCHAIN_ERC721 = 3;

    address private owner = makeAddr("owner");
    address private verifier = makeAddr("verifier");
    address private student = makeAddr("student");
    address private otherStudent = makeAddr("otherStudent");
    address private erc20Submission = makeAddr("erc20Submission");
    address private erc721Submission = makeAddr("erc721Submission");
    address private onchainSubmission = makeAddr("onchainSubmission");

    string private constant BASE_URI = "ipfs://quest/base.json";
    string private constant STAGE_ONE_URI = "ipfs://quest/erc20.json";
    string private constant STAGE_TWO_URI = "ipfs://quest/erc721.json";
    string private constant FINAL_URI = "ipfs://quest/onchain-erc721.json";

    function setUp() public {
        quest = new LearningQuest(owner, verifier);
        questNft = new LearningQuestNft(address(quest), [BASE_URI, STAGE_ONE_URI, STAGE_TWO_URI, FINAL_URI]);
    }

    function testVerifierCanCompleteStage() public {
        vm.prank(verifier);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);

        (bool completed, address contractAddress,) = quest.getStageCompletion(student, STAGE_ERC20);

        assertTrue(completed);
        assertEq(contractAddress, erc20Submission);
        assertEq(quest.getHighestCompletedStage(student), STAGE_ERC20);
        assertTrue(quest.isContractUsed(erc20Submission));
        assertEq(quest.getContractSubmitter(erc20Submission), student);
    }

    function testNonVerifierCannotCompleteStage() public {
        vm.prank(student);
        vm.expectRevert(LearningQuest.LearningQuest__OnlyVerifier.selector);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);
    }

    function testOwnerCanAddVerifier() public {
        address newVerifier = makeAddr("newVerifier");

        vm.prank(owner);
        quest.setVerifier(newVerifier, true);

        vm.prank(newVerifier);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);

        assertEq(quest.getHighestCompletedStage(student), STAGE_ERC20);
    }

    function testCannotCompleteTheSameStageTwice() public {
        vm.startPrank(verifier);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);

        vm.expectRevert(LearningQuest.LearningQuest__StageAlreadyCompleted.selector);
        quest.completeStage(student, STAGE_ERC20, erc721Submission);
        vm.stopPrank();
    }

    function testCannotReuseSubmittedContractAddress() public {
        vm.prank(verifier);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);

        vm.prank(verifier);
        vm.expectRevert(LearningQuest.LearningQuest__ContractAlreadyUsed.selector);
        quest.completeStage(otherStudent, STAGE_ERC20, erc20Submission);
    }

    function testCannotSkipPreviousStage() public {
        vm.prank(verifier);
        vm.expectRevert(LearningQuest.LearningQuest__PreviousStageIncomplete.selector);
        quest.completeStage(student, STAGE_ERC721, erc721Submission);
    }

    function testNftTokenUriEvolvesFromQuestProgress() public {
        vm.prank(student);
        questNft.mintQuestCard();

        assertEq(questNft.tokenURI(0), BASE_URI);

        vm.startPrank(verifier);
        quest.completeStage(student, STAGE_ERC20, erc20Submission);
        assertEq(questNft.tokenURI(0), STAGE_ONE_URI);

        quest.completeStage(student, STAGE_ERC721, erc721Submission);
        assertEq(questNft.tokenURI(0), STAGE_TWO_URI);

        quest.completeStage(student, STAGE_ONCHAIN_ERC721, onchainSubmission);
        assertEq(questNft.tokenURI(0), FINAL_URI);
        vm.stopPrank();
    }

    function testStudentCanOnlyMintOneQuestCard() public {
        vm.startPrank(student);
        questNft.mintQuestCard();

        vm.expectRevert(LearningQuestNft.LearningQuestNft__AlreadyMinted.selector);
        questNft.mintQuestCard();
        vm.stopPrank();
    }

    function testRefreshMetadataEmitsErc4906Event() public {
        vm.prank(student);
        questNft.mintQuestCard();

        vm.expectEmit(true, true, true, true);
        emit IERC4906.MetadataUpdate(0);
        questNft.refreshMetadata(0);
    }
}
