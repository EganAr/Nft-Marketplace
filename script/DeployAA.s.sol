// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {BasicNft} from "src/BasicNft.sol";
import {ListingNft} from "src/ListingNft.sol";
import {Paymaster} from "src/Paymaster.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";

contract DeployAA is Script {
    function run() public {
        deployAA();
    }

    function deployAA() public returns (BasicNft, ListingNft, HelperConfig, MinimalAccount, Paymaster) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        address entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
        BasicNft basicNft = new BasicNft();
        ListingNft listingNft = new ListingNft();
        MinimalAccount account = new MinimalAccount(entryPoint);
        Paymaster paymaster = new Paymaster(entryPoint);

        account.transferOwnership(config.account);
        paymaster.transferOwnership(config.account);
        helperConfig.updateConfig(entryPoint, address(account), address(paymaster));
        vm.stopBroadcast();

        console.log("DEPLOYED ACCOUNT ABSTRACTION");
        console.log("Address Paymaster Owner", paymaster.owner());
        console.log("Address MinimalAccount Owner", account.owner());
        console.log("Address Paymaster ", address(paymaster));
        console.log("Address MinimalAccount ", address(account));
        return (basicNft, listingNft, helperConfig, account, paymaster);
    }
}
// source .env
// forge script script/DeployAA.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --broadcast --verify -vvvv
