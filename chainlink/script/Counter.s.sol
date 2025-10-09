// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Counter} from "../src/Counter.sol";
import {Script} from "forge-std/Script.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract CounterScript is Script {
    Counter public counter;

    function setUp() public {}

    function run() public {
        // Deployed contract address
        address consumerAddress = 0x38c8b98A2Cb36a55234323D7eCCD36ad3bFC5954;

        // Interface your contract
        AggregatorV3Interface consumer = AggregatorV3Interface(consumerAddress);

        // (int256 rawPrice, uint256 adjustedPrice) = consumer
        //     .getPriceFeedAdjusted();
    }
}
