//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/fund-me.sol";

contract FundMeScript is Script {
    function run() external returns (FundMe) {
        vm.startBroadcast();
        FundMe deployedFundMe = new FundMe(
            0x6D41d1dc818112880b40e26BD6FD347E41008eDA
        );
        vm.stopBroadcast();
        return deployedFundMe;
    }
    // return FundMe;
}
