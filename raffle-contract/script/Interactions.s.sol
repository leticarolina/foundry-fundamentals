// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/TokenToFundVRF.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

/*//////////////////////////////////////////////////////////////
                           CREATE SUBSCRIPTION
    //////////////////////////////////////////////////////////////*/
// This is a script to create a Chainlink VRF subscription and fund it with tokens
// It can be used to create a subscription for Chainlink VRF on any network, including local development networks.
contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig(); //deploying a new instance of the HelperConfig contract in the script environment
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator; // calling the getConfig() function from the helperConfig instance, which returns a NetworkConfig struct with all your network-specific settings (entranceFee, interval, etc).
        (uint256 subId, ) = createSubscription(vrfCoordinator); // create a new subscription using the vrfCoordinator address from the config
        return (subId, vrfCoordinator); // return the subscription ID and VRF Coordinator address
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256, address) {
        // console.log(
        //     "creating subscription of VRFCoordinatorV2 on chain:",
        //     block.chainid
        // );
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        // console.log("subscription created with id:", subId);
        // console.log("update the subscriptionId in the HelperConfig.s.sol file");

        return (subId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

/*//////////////////////////////////////////////////////////////
                           FUND SUBSCRIPTION
    //////////////////////////////////////////////////////////////*/
// This script is used to fund the Chainlink VRF subscription with LINK tokens
// It can be used to fund the subscription on any network, including local development networks.
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 10 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().token;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log(
                "New SubId Created! ",
                subscriptionId,
                "VRF Address: ",
                vrfCoordinator
            );
        }

        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log("funding subscription:", subscriptionId);
        console.log("using vrfCoordinator:", vrfCoordinator);
        console.log("on chainId:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(linkToken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linkToken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

/*//////////////////////////////////////////////////////////////
                           ADDING CONSUMER
    //////////////////////////////////////////////////////////////*/
// This script is used to add a consumer to the Chainlink VRF subscription
contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCoordinator,
        uint256 subscriptionId
    ) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using VRFCoordinator: ", vrfCoordinator);
        console.log("On chain id: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            raffle
        );
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log(
                "New SubId Created! ",
                subscriptionId,
                "VRF Address: ",
                vrfCoordinator
            );
        }

        addConsumer(raffle, vrfCoordinator, subscriptionId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}

// //the redo
// /*//////////////////////////////////////////////////////////////
//                            CREATE SUBSCRIPTION
// //////////////////////////////////////////////////////////////*/
// contract CreateSubscription is Script {
//     function createSubscription(
//         address vrfCoordinator
//     ) public returns (uint256, address) {
//         console.log("Creating VRF subscription on chain:", block.chainid);
//         vm.startBroadcast();
//         uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
//             .createSubscription();
//         vm.stopBroadcast();
//         console.log("Subscription created with ID:", subId);
//         return (subId, vrfCoordinator);
//     }
// }

// /*//////////////////////////////////////////////////////////////
//                            FUND SUBSCRIPTION
// //////////////////////////////////////////////////////////////*/
// contract FundSubscription is Script {
//     uint256 public constant FUND_AMOUNT = 3 ether;

//     function fundSubscription(
//         address vrfCoordinator,
//         uint256 subscriptionId,
//         address linkToken
//     ) public {
//         console.log("Funding subscription:", subscriptionId);
//         console.log("Using VRFCoordinator:", vrfCoordinator);
//         console.log("On chainId:", block.chainid);

//         vm.startBroadcast();
//         if (block.chainid == 31337) {
//             VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
//                 subscriptionId,
//                 FUND_AMOUNT
//             );
//         } else {
//             LinkToken(linkToken).transferAndCall(
//                 vrfCoordinator,
//                 FUND_AMOUNT,
//                 abi.encode(subscriptionId)
//             );
//         }
//         vm.stopBroadcast();
//     }
// }

// /*//////////////////////////////////////////////////////////////
//                            ADD CONSUMER
// //////////////////////////////////////////////////////////////*/
// contract AddConsumer is Script {
//     function addConsumer(
//         address raffle,
//         address vrfCoordinator,
//         uint256 subscriptionId
//     ) public {
//         console.log("Adding consumer:", raffle);
//         console.log("Using VRFCoordinator:", vrfCoordinator);
//         console.log("On chainId:", block.chainid);

//         vm.startBroadcast();
//         VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
//             subscriptionId,
//             raffle
//         );
//         vm.stopBroadcast();
//     }
// }
