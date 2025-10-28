//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address mostRecentDeploy = DevOpsTools.get_most_recent_deployment(
            "ERC1967Proxy",
            block.chainid
        );

        vm.startBroadcast();
        BoxV2 newBox = new BoxV2();
        vm.stopBroadcast();
        address proxy = upgradeBox(mostRecentDeploy, address(newBox));
        return proxy;
    }

    function upgradeBox(
        address proxyDeployed,
        address upgradeImplementation
    ) public returns (address) {
        vm.startBroadcast();
        BoxV1 proxyContract = BoxV1(payable(proxyDeployed));
        proxyContract.upgradeToAndCall(address(upgradeImplementation), ""); //proxy contract now points to this new address
        vm.stopBroadcast();
        return address(proxyContract);
    }
}
