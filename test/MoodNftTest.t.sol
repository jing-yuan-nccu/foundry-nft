// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {DeployMoodNft} from "../script/DeployMoodNft.s.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {FoundryZkSyncChecker} from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";

contract MoodNftTest is Test, ZkSyncChainChecker, FoundryZkSyncChecker {
    string constant NFT_NAME = "Mood NFT";
    string constant NFT_SYMBOL = "MN";

    MoodNft public moodNft;
    DeployMoodNft public deployer;

    address public constant USER = address(1);

    function setUp() public {
        deployer = new DeployMoodNft();
        if (!isZkSyncChain()) {
            moodNft = deployer.run();
        } else {
            string memory sadSvg = vm.readFile("./img/sad.svg");
            string memory happySvg = vm.readFile("./img/happy.svg");
            moodNft = new MoodNft(deployer.svgToImageURI(sadSvg), deployer.svgToImageURI(happySvg));
        }
    }

    function testInitializedCorrectly() public view {
        assertEq(moodNft.name(), NFT_NAME);
        assertEq(moodNft.symbol(), NFT_SYMBOL);
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        moodNft.mintNft();

        assertEq(moodNft.balanceOf(USER), 1);
    }

    function testTokenURIDefaultIsCorrectlySet() public {
        vm.prank(USER);
        moodNft.mintNft();

        assertEq(moodNft.tokenURI(0), _expectedTokenUri(true));
    }

    function testFlipTokenToSad() public {
        vm.prank(USER);
        moodNft.mintNft();

        vm.prank(USER);
        moodNft.flipMood(0);

        assertEq(moodNft.tokenURI(0), _expectedTokenUri(false));
    }

    function testEventRecordsCorrectTokenIdOnMinting() public {
        uint256 currentAvailableTokenId = moodNft.getTokenCounter();

        vm.prank(USER);
        vm.recordLogs();
        moodNft.mintNft();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 tokenIdProto = entries[0].topics[3];
        uint256 tokenId = uint256(tokenIdProto);

        assertEq(tokenId, currentAvailableTokenId);
    }

    function _expectedTokenUri(bool isHappy) internal view returns (string memory) {
        string memory sadSvg = vm.readFile("./img/sad.svg");
        string memory happySvg = vm.readFile("./img/happy.svg");
        string memory imageURI = isHappy ? deployer.svgToImageURI(happySvg) : deployer.svgToImageURI(sadSvg);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            moodNft.name(),
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
}
