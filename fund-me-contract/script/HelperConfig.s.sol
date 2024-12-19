// SPDX-License-Identifier: MIT
//1.deploy mocks when we are on a local anvil chain
//2.keep track of contract address accross different chains

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig {
    // If we are on a local Anvil, we deploy the mocks // Else, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed; //ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = GetAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //price feed adddress
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function GetAnvilEthConfig() public pure returns (NetworkConfig memory) {
        //price feed adddress
    }
}
