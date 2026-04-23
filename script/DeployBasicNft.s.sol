// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BasicNft} from "src/BasicNft.sol";

contract DeployBasicNft is Script {
    string public constant DEFAULT_BASE_TOKEN_URI = "ipfs://YOUR_METADATA_FOLDER_CID/";

    function run() external returns (BasicNft) {
        string memory baseTokenUri = vm.envOr("IPFS_BASE_TOKEN_URI", DEFAULT_BASE_TOKEN_URI);

        vm.startBroadcast();
        BasicNft basicNft = new BasicNft(baseTokenUri);
        vm.stopBroadcast();

        return basicNft;
    }
}
