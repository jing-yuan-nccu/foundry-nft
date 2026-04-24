// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNft} from "src/BasicNft.sol";
import {MoodNft} from "src/MoodNft.sol";

contract MintBasicNft is Script {
    function run() external {
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);

        vm.startBroadcast();
        BasicNft(mostRecentDeployment).mintNft();
        vm.stopBroadcast();
    }
}

contract UpdateBasicNftBaseUri is Script {
    function run() external {
        string memory newBaseTokenUri = vm.envString("NEW_IPFS_BASE_TOKEN_URI");
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);

        vm.startBroadcast();
        BasicNft(mostRecentDeployment).setBaseTokenUri(newBaseTokenUri);
        vm.stopBroadcast();
    }
}

contract MintMoodNft is Script {
    function run() external {
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);

        vm.startBroadcast();
        MoodNft(mostRecentDeployment).mintNft();
        vm.stopBroadcast();
    }
}

contract FlipMoodNft is Script {
    function run() external {
        uint256 tokenId = vm.envUint("TOKEN_ID");
        address mostRecentDeployment =
            DevOpsTools.get_most_recent_deployment("MoodNft", block.chainid);

        vm.startBroadcast();
        MoodNft(mostRecentDeployment).flipMood(tokenId);
        vm.stopBroadcast();
    }
}
