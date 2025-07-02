//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {FundMe} from "../src/fund-me.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract FundMeScript is Script {
    HelperConfig helperConfig = new HelperConfig();
    address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

    function run() external returns (FundMe) {
        vm.startBroadcast();
        FundMe deployedFundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return deployedFundMe;
    }
    // return FundMe;
}
