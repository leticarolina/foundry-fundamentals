//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

// import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        //get_most_recent_deployment = Helper gets what address was last deployed for that contract name on this chain.
        //variable for the proxy address deployed before. it’s the proxy address itself, that proxy currently delegates to BoxV1 (the first logic)
        // address mostRecentDeploy = DevOpsTools.get_most_recent_deployment(
        //     "ERC1967Proxy",
        //     block.chainid
        // );
        address mostRecentDeploy = 0x096De44916a641f67f168475EA706A8d3053E36c; //proxy

        vm.startBroadcast();
        BoxV2 newBox = new BoxV2(); //deploy NEW implementation contract
        vm.stopBroadcast();
        //perform the upgrade
        address proxy = upgradeBox(mostRecentDeploy, address(newBox));
        return proxy;
    }

    function upgradeBox(
        address proxyDeployed,
        address upgradeImplementation
    ) public returns (address) {
        vm.startBroadcast();
        // Treat the proxy address as if it's a BoxV1 (because it exposes upgrade fn)
        //cast the proxy as BoxV1 because its current brain (implementation) is BoxV1, just casting the proxy to use the ABI of the implementation.
        //If you currently have BoxV2 implemented and want to upgrade to v3, this ABI might change you’d have to refactor the script or write a new script (e.g. UpgradeBoxV2toV3.s.sol)
        BoxV1 proxyContract = BoxV1(payable(proxyDeployed));

        // Ask proxy to upgrade its implementation to the new address
        proxyContract.upgradeToAndCall(address(upgradeImplementation), ""); //proxy contract now points to this new address
        vm.stopBroadcast();
        return address(proxyContract); //After the upgrade, _authorizeUpgrade logic now comes from BoxV2
    }
}
