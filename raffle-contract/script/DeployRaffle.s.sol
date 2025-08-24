// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol"; //import to use some foundry features like vm.startBroadcast() and console.log()
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol"; //importing to be able to use the network configuration values
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol"; //importing to create, fund a subscription and add consumer
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; //mock contract to simulate Chainlink VRF Coordinator interactions

contract DeployRaffle is Script, CodeConstants {
    Raffle public raffle; //variable that will hold the address of the deployed Raffle instance

    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); //deploying a new instance of the HelperConfig to access the network configuration values
        AddConsumer addConsumer = new AddConsumer(); //deploying copy of addConsumer script to be able to call its addConsumer function later
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // calling the getConfig() function from the helperConfig instance, which returns a NetworkConfig struct with all your network-specific settings (entranceFee, interval, etc).

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

        if (config.subscriptionId != 0) {
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.token,
                config.account
            );
            helperConfig.setConfig(block.chainid, config);
        }

        //Broadcasts deployment of Raffle with the config values.
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

        return (raffle, helperConfig);
    }
}
