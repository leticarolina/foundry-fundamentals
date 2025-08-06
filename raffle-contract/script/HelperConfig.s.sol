//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    // VRF Mock values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE = 0.25 ether; // 0.25 LINK per gas
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                callbackGasLimit: 500000, // 500,000 gas
                subscriptionId: 0
            });
    }

    function getLocalConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds
                vrfCoordinator: address(0),
                keyHash: "",
                callbackGasLimit: 500000,
                subscriptionId: 0
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // If the local chain ID is already configured, return it.
        if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator == address(0)) {
            // networkConfigs[LOCAL_CHAIN_ID] = getLocalConfig();
            // 1. Create the base config with default values
            NetworkConfig memory localConfig = getLocalConfig();
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
                    MOCK_BASE_FEE,
                    MOCK_GAS_PRICE,
                    MOCK_WEI_PER_UNIT_LINK
                );
            vm.stopBroadcast();

            // 3. Update the localConfig with the mock address
            localConfig.vrfCoordinator = address(vrfCoordinatorMock);

            // 4. Store it in the mapping
            networkConfigs[LOCAL_CHAIN_ID] = localConfig;
        }
        return networkConfigs[LOCAL_CHAIN_ID];

        // If not, create a new mock VRFCoordinator and return the config.
        // vm.startBroadcast();
        // VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
        //     MOCK_BASE_FEE,
        //     MOCK_GAS_PRICE,
        //     MOCK_WEI_PER_UNIT_LINK
        // );
        // vm.stopBroadcast();
        // 4. Store it in the mapping

        // Now build the config with that mock and store it

        // NetworkConfig({
        //     entranceFee: 0.01 ether,
        //     interval: 30, // 30 seconds
        //     vrfCoordinator: address(vrfCoordinatorMock),
        //     // gasLane value doesn't matter.
        //     keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        //     subscriptionId: 0,
        //     callbackGasLimit: 500_000
        // });
    }
}
