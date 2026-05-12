// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PracticeV1} from "../src/PracticeV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployPracticeV1 is Script {
    // Mock reward token address for testing — replace with real one on mainnet
    address constant MOCK_REWARD_TOKEN = address(0x123);
    uint256 constant COOLDOWN_PERIOD = 1 days;
    uint256 constant MAX_NAME_LENGTH = 6;

    function run() external returns (address proxy) {
        vm.startBroadcast();

        proxy = deploy();

        vm.stopBroadcast();

        console.log(
            "PracticeV1 implementation deployed at:",
            getImplementation(proxy)
        );
        console.log("Proxy deployed at:", proxy);
        console.log("Version:", PracticeV1(proxy).getVersion());
        console.log("Owner:", PracticeV1(proxy).owner());
        console.log("Reward token:", PracticeV1(proxy).rewardToken());
    }

    function deploy() public returns (address proxy) {
        // 1. Deploy implementation
        // _disableInitializers() fires in constructor
        // implementation is deployed but has no state, initialize() not called yet
        PracticeV1 implementation = new PracticeV1();

        // 2. Encode initialize() call with your params,
        // nothing has been called yet, just packing the call into bytes
        bytes memory initData = abi.encodeWithSelector(
            PracticeV1.initialize.selector,
            MOCK_REWARD_TOKEN,
            COOLDOWN_PERIOD,
            MAX_NAME_LENGTH
        );

        // 3. Deploy proxy WITH initData  — initialize() runs atomically in the same tx
        // proxy deploys AND immediately calls initialize() through delegatecall, so the state is set up in the proxy right away
        // initialize() runs in proxy's storage context
        // owner, rewardToken, cooldownPeriod all written to PROXY storage
        ERC1967Proxy proxyContract = new ERC1967Proxy(
            address(implementation),
            initData
        );

        proxy = address(proxyContract);
    }

    /// @dev Helper to read the current implementation address from proxy storage
    function getImplementation(address proxy) public view returns (address) {
        // ERC1967 implementation slot
        bytes32 slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 value = vm.load(proxy, slot);
        return address(uint160(uint256(value)));
    }
}
