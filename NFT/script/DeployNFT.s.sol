// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {LeticiaNFT} from "../src/BasicNFT.sol";

contract DeployNFT is Script {
    function run() external returns (LeticiaNFT) {
        vm.startBroadcast();
        LeticiaNFT basicNft = new LeticiaNFT();
        vm.stopBroadcast();
        return basicNft;
    }
}
