// SPDX-License-Identifier: MIT
//1.deploy mocks when we are on a local anvil chain
//2.keep track of contract address accross different chains

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// This contract is designed to help configure the price feed for different blockchain networks.
// If we are on a local Anvil, we deploy the mocks // Else, grab the existing address from the live network

contract HelperConfig is Script {
    // the main variable to store the active configuration for the current network
    NetworkConfig public activeNetworkConfig;
    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 200e8;

    //struct is for defining multiple data types into one unit
    //can think as a way to group related variables together under a single name making code easier to manage.
    struct NetworkConfig {
        address priceFeed; //The address of the price feed ETH/USD for the network
    }

    //constructor is executed when contract is deployed, it will initiate the 'activeNetworkConfig' based on the blockchain's chain ID.
    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        }
        // Check if the blockchain's chain ID is 11155111, which corresponds to the Sepolia testnet. each blockcain has its own chainID
        else if (block.chainid == 11155111) {
            // If the chain ID is Sepolia, call the `getSepoliaEthConfig` function to get Sepolia's configuration.
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            // If it's not Sepolia, assume we are running on a local Anvil network.
            activeNetworkConfig = GetOrCreateAnvilEthConfig();
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return mainnetConfig;
    }

    // Function to return the configuration specific to the Sepolia testnet.
    // It's declared `pure` because it doesn't modify the state or read state variables.
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //NetworkConfig memory sepoliaConfig declares a new variable, the type is the struct
        //NetworkConfig({...}) is creating a new NetworkConfig struct with specific values for its fields.
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            // The Sepolia testnet's ETH/USD price feed address (this is hardcoded here).
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        //then returning a fully formed NetworkConfig struct instance.
        return sepoliaConfig;
    }

    function GetOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check for Existing Configuration: if a configuration already exists (priceFeed is not the zero address)
        if (activeNetworkConfig.priceFeed != address(0)) {
            // If address not 0 means activeNetworkConfig already has a priceFeed, return it (no need to create a new one)
            return activeNetworkConfig;
        }

        vm.startBroadcast(config.account);
        // Deploy a new MockV3Aggregator contract (a fake price feed for testing purposes)
        // DECIMALS: Number of decimals the mock price feed supports
        // INITIAL_PRICE: The initial price value for the mock price feed
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        // Create a new NetworkConfig struct for the Anvil network

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        // Return the newly created Anvil network configuration
        return anvilConfig;
    }
}
