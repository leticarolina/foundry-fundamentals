// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract DeployMoodNft is Script {
    function run() external returns (MoodNft) {
        vm.startBroadcast();
        MoodNft moodNft = new MoodNft();
        vm.stopBroadcast();
        return moodNft;
    }
}
