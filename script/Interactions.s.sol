// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BasicNft} from "src/BasicNft.sol";
import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract MintBasicNft is Script {
    string public constant PUG_URI = "https://gateway.pinata.cloud/ipfs/QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW";

    function run() public {
        address recentlyDeploy = DevOpsTools.get_most_recent_deployment("BasicNft", block.chainid);
        mintNftOnContract(recentlyDeploy);
    }

    function mintNftOnContract(address basicNftAddress) public {
        vm.startBroadcast();
        BasicNft(basicNftAddress).mintNft(PUG_URI);
        vm.stopBroadcast();
    }
}
