// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;

    function run() public {}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); //deploying a new instance of the HelperConfig contract in the script environment
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // calling the getConfig() function from the helperConfig instance, which returns a NetworkConfig struct with all your network-specific settings (entranceFee, interval, etc).

        if (config.subscriptionId == 0) {
            //create a new subscription if subscriptionId is 0
            CreateSubscription createSubscription = new CreateSubscription();
            // (config.subscriptionId, config.vrfCoordinator) = createSubscription
            //     .createSubscription(config.vrfCoordinator);
            (uint256 subId, address vrfCoord) = createSubscription
                .createSubscription(config.vrfCoordinator);
            config.subscriptionId = uint64(subId);
            config.vrfCoordinator = vrfCoord;
        }

        vm.startBroadcast();
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
