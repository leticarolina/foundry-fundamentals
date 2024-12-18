//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// This interface allows your contract to interact with a Chainlink price feed
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
// /Users/admin/Documents/GitHub/foundry-fundamentals/fund-me-contract/lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library Converter {
    //AggregatorV3Interface is an interface, meaning it's a definition of how the contract at the specified address is structured.
    //It tells the Solidity compiler which functions exist in the contract and how to interact with it.
    //feedPrice: This is a variable that holds a reference to the existing contract at the specified address.
    //AggregatorV3Interface feedPrice: This creates an instance of the AggregatorV3Interface contract at the specified address (0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF)
    //you're connecting to a contract that is already deployed at 0xAddress and using its interface to call functions like latestRoundData().
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //  AggregatorV3Interface feedPrice = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        // AggregatorV3Interface feedPrice = AggregatorV3Interface(
        //     0x6D41d1dc818112880b40e26BD6FD347E41008eDA
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //answer = 244725000000
        return uint256(answer) * 1e18; //current example: 244,725,000,000,000,000,000,000,000,000
        //this function retrieves the price of 1 ETH in USD, scaled up by 1e18 to handle decimal precision.
    }

    //When a function takes an uint256 parameter intended to represent Ether, it is expected to be in wei.
    //The division by 1e18 is necessary to convert from wei to Ether, ensuring the units align correctly.
    function getConversionRate(
        uint256 ethAmountInWei,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); // Step 1: Get the current price of 1 ETH in USD (scaled up by 1e18)
        uint256 ethAmountInUsd = (ethPrice * ethAmountInWei) / 1e18; //Step 2: Calculate the USD value of the specified ETH amount.You divide by 1e18 to scale the result back down to a human-readable number, since ethPrice was scaled up.
        return ethAmountInUsd; // Step 3: Return the calculated amount in USD
    }
}
