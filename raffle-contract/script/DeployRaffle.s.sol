// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
contract DeployRaffle is Script, CodeConstants {
    Raffle public raffle;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); //deploying a new instance of the HelperConfig contract in the script environment
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // calling the getConfig() function from the helperConfig instance, which returns a NetworkConfig struct with all your network-specific settings (entranceFee, interval, etc).

        // if (config.subscriptionId == 0) {
        //     //create a new subscription if subscriptionId is 0
        //     CreateSubscription createSubscription = new CreateSubscription();
        //     (config.subscriptionId, config.vrfCoordinator) = createSubscription
        //         .createSubscription(config.vrfCoordinator);
        //     // (uint256 subId, address vrfCoord) = createSubscription;
        //     //     .createSubscription(config.vrfCoordinator);
        //     // config.subscriptionId = uint64(subId);
        //     // config.vrfCoordinator = vrfCoord;
        //     // console.logUint(subId);

        //     //fund the subscription with LINK tokens
        //     FundSubscription fundSubscription = new FundSubscription();
        //     fundSubscription.fundSubscription(
        //         config.vrfCoordinator,
        //         config.subscriptionId,
        //         config.token
        //     );

        //     // helperConfig.setConfig(block.chainid, config);
        // }

        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription
                .createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.token,
                config.account
            );
            helperConfig.setConfig(block.chainid, config);
        }

        // if (block.chainid == 31337) {
        //     FundSubscription fund = new FundSubscription();
        //     fund.fundSubscription(
        //         config.vrfCoordinator,
        //         config.subscriptionId,
        //         config.token,
        //         config.account
        //     );
        // }

        vm.startBroadcast(config.account); // Start broadcasting transactions from the specified account
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        // VRFCoordinatorV2_5Mock(config.vrfCoordinator).addConsumer(
        //     config.subscriptionId,
        //     address(raffle)
        // );

        return (raffle, helperConfig);
    }
}
