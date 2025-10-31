//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol"; //lets deploy a proxy instance

contract DeployBox is Script {
    function run() external returns (address) {
        address proxy = deployBox();
        return proxy;
    }

    function deployBox() public returns (address) {
        vm.startBroadcast();
        //1. Deploy the logic (implementation) contract
        BoxV1 box = new BoxV1();

        // 2. Deploy proxy that points to that implementation
        // ERC1967Proxy constructor takes: implementation address, some init call data (bytes) to run immediately
        ERC1967Proxy proxy = new ERC1967Proxy(address(box), ""); // Encode the initializer call (replaces constructor)

        // 3. Manually call initialize() on the proxy instance

        BoxV1(address(proxy)).initialize(); // Deploy the proxy pointing to the implementation
        vm.stopBroadcast();
        return address(proxy);
    }
}
