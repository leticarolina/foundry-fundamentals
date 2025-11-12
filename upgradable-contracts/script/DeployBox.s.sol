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

        // 2. Deploy proxy contract that points to that implementation box (2 different contracts deployed)
        // ERC1967Proxy constructor takes: implementation address, some init call data (bytes) to run immediately
        //so proxy will delegate future calls to implementation address 
        //"Whenever someone calls you (proxy), forward the call to this implementation (BoxV1)"
        ERC1967Proxy proxy = new ERC1967Proxy(address(box), ""); // Encode the initializer call (replaces constructor)

        // 3. Manually call initialize() on the proxy instance
        //Now call initialize() from BoxV1, but through the proxy, not on the implementation. initialize() will write state into the proxy’s storage.
        BoxV1(address(proxy)).initialize(); // Deploy the proxy pointing to the implementation, This sets the owner etc
        //Meaning: the logic runs using BoxV1’s code, but any variable writes happen inside the proxy’s storage.
        vm.stopBroadcast();

        //Users will now call the proxy address for getNumber, etc. never the implementation directly
        return address(proxy); 
    }
}
