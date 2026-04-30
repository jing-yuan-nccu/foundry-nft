// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {LearningQuest} from "src/quest/LearningQuest.sol";
import {LearningQuestNft} from "src/quest/LearningQuestNft.sol";

contract DeployLearningQuest is Script {
    string private constant DEFAULT_BASE_URI = "http://127.0.0.1:5173/quest/metadata/base.json";
    string private constant DEFAULT_ERC20_URI = "http://127.0.0.1:5173/quest/metadata/erc20.json";
    string private constant DEFAULT_ERC721_URI = "http://127.0.0.1:5173/quest/metadata/erc721.json";
    string private constant DEFAULT_ONCHAIN_URI = "http://127.0.0.1:5173/quest/metadata/onchain-erc721.json";

    function run() external returns (LearningQuest, LearningQuestNft) {
        address verifier = vm.envOr("QUEST_VERIFIER_ADDRESS", msg.sender);
        string[4] memory stageUris = [
            vm.envOr("QUEST_BASE_URI", DEFAULT_BASE_URI),
            vm.envOr("QUEST_ERC20_URI", DEFAULT_ERC20_URI),
            vm.envOr("QUEST_ERC721_URI", DEFAULT_ERC721_URI),
            vm.envOr("QUEST_ONCHAIN_ERC721_URI", DEFAULT_ONCHAIN_URI)
        ];

        vm.startBroadcast();
        LearningQuest quest = new LearningQuest(msg.sender, verifier);
        LearningQuestNft questNft = new LearningQuestNft(address(quest), stageUris);
        vm.stopBroadcast();

        return (quest, questNft);
    }
}
