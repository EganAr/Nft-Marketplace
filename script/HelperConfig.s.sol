// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {EntryPoint} from "lib/account-abstraction/contracts/core/EntryPoint.sol";
import {Paymaster} from "src/Paymaster.sol";
import {MinimalAccount} from "src/MinimalAccount.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
        address paymaster;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant ANVIL_LOCAL_CHAIN_ID = 31337;
    address constant PAYMASTER = 0x0000000000000000000000000000000000000000;
    address constant ANVIL_DEFAULT_KEY = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        // networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return getEthSepoliaConfig();
        } else if (block.chainid == ANVIL_LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].paymaster != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account: 0xFf17616E555e54821BF79435eEefE1d172B4b08c,
            paymaster: address(0)
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.paymaster != address(0)) {
            return localNetworkConfig;
        }

        console2.log("Deploying new EntryPoint and Paymaster for local testing...");
        vm.startBroadcast();
        EntryPoint entryPoint = new EntryPoint();
        Paymaster paymaster = new Paymaster(address(entryPoint));
        vm.stopBroadcast();

        localNetworkConfig =
            NetworkConfig({entryPoint: address(entryPoint), account: ANVIL_DEFAULT_KEY, paymaster: address(paymaster)});

        return localNetworkConfig;
    }

    function updateConfig(address _entryPoint, address _account, address _paymaster) external {
        localNetworkConfig.entryPoint = _entryPoint;
        localNetworkConfig.account = _account;
        localNetworkConfig.paymaster = _paymaster;
    }
}
