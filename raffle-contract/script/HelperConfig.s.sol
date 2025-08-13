//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {VRFCoordinatorV2PlusMock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "../test/mocks/TokenToFundVRF.sol";

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
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address token; // Optional, can be used for native token payments
        uint256 account;
    }

    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    // address public constant DEFAULT_ANVIL_KEY =
    //     0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        networkConfigs[chainId] = networkConfig;
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

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether, // 1e16
                interval: 30, // 30 seconds
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //this is the keyhash aka gas lane for Sepolia
                callbackGasLimit: 500000, // 500,000 gas
                subscriptionId: 59348555989737605849604285057428249510813332769843048132307428824801730465258, // Subscription ID for Sepolia
                token: 0x779877A7B0D9E8603169DdbD7836e478b4624789, // Sepolia ETH token address,
                account: vm.envUint("SEPOLIA_PK") // Optional, can be used for native token payments,
            });
    }

    // function getLocalConfig(
    //     address linkToken
    // ) public pure returns (NetworkConfig memory) {
    //     return
    //         NetworkConfig({
    //             entranceFee: 0.01 ether,
    //             interval: 30, // 30 seconds
    //             vrfCoordinator: address(0),
    //             keyHash: "",
    //             callbackGasLimit: 500000,
    //             subscriptionId: subscriptionId,
    //             token: linkToken
    //         });
    // }

    // function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    //     // If the local chain ID is already configured, return it.
    //     if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator == address(0)) {
    //         // networkConfigs[LOCAL_CHAIN_ID] = getLocalConfig();
    //         // 1. Create the base config with default values
    //         // NetworkConfig memory localConfig = getLocalConfig(address(linkToken));

    //         // 2. Deploy a mock VRFCoordinator if it doesn't exist
    //         // This is only done if the vrfCoordinator address is not set.
    //         vm.startBroadcast();
    //         VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
    //                 MOCK_BASE_FEE,
    //                 MOCK_GAS_PRICE,
    //                 MOCK_WEI_PER_UNIT_LINK
    //             );
    //         LinkToken linkToken = new LinkToken();
    //         vm.stopBroadcast();

    //         NetworkConfig memory localConfig = getLocalConfig(
    //             address(linkToken)
    //         );
    //         // 3. Update the localConfig with the mock address
    //         localConfig.vrfCoordinator = address(vrfCoordinatorMock);

    //         // 4. Store it in the mapping
    //         networkConfigs[LOCAL_CHAIN_ID] = localConfig;
    //     }
    //     return networkConfigs[LOCAL_CHAIN_ID];

    //     // If not, create a new mock VRFCoordinator and return the config.
    //     // vm.startBroadcast();
    //     // VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
    //     //     MOCK_BASE_FEE,
    //     //     MOCK_GAS_PRICE,
    //     //     MOCK_WEI_PER_UNIT_LINK
    //     // );
    //     // vm.stopBroadcast();
    //     // 4. Store it in the mapping

    //     // Now build the config with that mock and store it

    //     // NetworkConfig({
    //     //     entranceFee: 0.01 ether,
    //     //     interval: 30, // 30 seconds
    //     //     vrfCoordinator: address(vrfCoordinatorMock),
    //     //     // gasLane value doesn't matter.
    //     //     keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
    //     //     subscriptionId: 0,
    //     //     callbackGasLimit: 500_000
    //     // });
    // }
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // If the local chain ID is already configured, return it.
        //this means if the local chain ID is already set in the mapping, return the existing config.
        if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }

        console.log(unicode" Deploying local mocks...");
        // If not, create a new mock VRFCoordinator and return the config.
        vm.startBroadcast(DEFAULT_ANVIL_KEY);
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_PER_UNIT_LINK
        );

        LinkToken linkToken = new LinkToken();

        // uint256 subscriptionId = 25027070020321881340250942419870798739630753771498781873077165221537535202702;
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();

        // vrfCoordinatorMock.fundSubscription(subscriptionId, 10 ether);

        // VRFCoordinatorV2_5Mock(vrfCoordinatorMock).fundSubscription(
        //     subscriptionId,
        //     10 ether
        // );

        vm.stopBroadcast();

        NetworkConfig memory localConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            keyHash: 0x0, // gas lane doesn't matter for local tests
            callbackGasLimit: 500000,
            subscriptionId: subscriptionId, // use the created subscription ID
            token: address(linkToken), // Link token address for local tests
            account: DEFAULT_ANVIL_KEY // Default sender address for local tests provided by Foundry
        });

        networkConfigs[LOCAL_CHAIN_ID] = localConfig;
        return localConfig;
    }
}
