// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BasicNft} from "src/BasicNft.sol";
import {ListingNft} from "src/ListingNft.sol";
import {Script} from "forge-std/Script.sol";

contract DeployBasicNft is Script {
    function run() public returns (BasicNft, ListingNft) {
        vm.startBroadcast();
        BasicNft basicNft = new BasicNft();
        ListingNft listingNft = new ListingNft();
        vm.stopBroadcast();
        return (basicNft, listingNft);
    }
}
