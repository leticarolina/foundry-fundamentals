// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PracticeV1} from "../src/PracticeV1.sol";
import {PracticeV2} from "../src/PracticeV2.sol";

contract UpgradePracticeV2 is Script {
    // Replace with your actual proxy address after deploying V1
    address constant PROXY_ADDRESS = 0x401f37F60fCB99072E2d010D9272441De947396E; // <-- fill this in

    function run() external {
        require(PROXY_ADDRESS != address(0), "Set PROXY_ADDRESS first");

        vm.startBroadcast();

        upgrade(PROXY_ADDRESS);

        vm.stopBroadcast();
    }

    function upgrade(address proxy) public returns (address newImplementation) {
        // 1. Deploy new implementation
        PracticeV2 implementationV2 = new PracticeV2();
        newImplementation = address(implementationV2);

        console.log("New implementation deployed at:", newImplementation);
        console.log("Version before upgrade:", PracticeV1(proxy).getVersion());

        // 2. Upgrade proxy to point to new implementation
        // upgradeToAndCall(newImpl, data)
        // data is empty "" because we do NOT call initialize() again
        // all existing state in proxy is preserved
        PracticeV1(proxy).upgradeToAndCall(newImplementation, "");

        // 3. Verify
        console.log("Version after upgrade:", PracticeV2(proxy).getVersion());
        console.log("Owner still:", PracticeV2(proxy).owner()); // should be same owner
        console.log("Reward token still:", PracticeV2(proxy).rewardToken()); // should be same value
        console.log(
            "Total registered still:",
            PracticeV2(proxy).totalRegistered()
        ); // should be same count

        return newImplementation;
    }
}
