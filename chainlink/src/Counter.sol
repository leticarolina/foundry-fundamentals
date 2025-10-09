// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Counter {
    uint256 public number;
    AggregatorV3Interface public priceFeedInterface;

    constructor() {
        priceFeedInterface = AggregatorV3Interface(
            0x38c8b98A2Cb36a55234323D7eCCD36ad3bFC5954
        );
    }

    function getPriceFeedAdjusted() public view returns (int256, uint256) {
        (, int256 answer, , , ) = priceFeedInterface.latestRoundData();
        require(answer > 0, "null price");
        uint256 adjustedPrice = uint256(answer) * 1e10;
        return (answer, adjustedPrice);
    }

    function getSimplePrice() public view returns (int256) {
        (, int256 answer, , , ) = priceFeedInterface.latestRoundData();
        return answer;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
