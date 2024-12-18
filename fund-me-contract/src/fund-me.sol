//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Converter} from "./Converter.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

using Converter for uint256;

// you can define custom errors to provide meaningful descriptions for conditions that fail in your smart contract
//error is the keyword used to define a custom error.
//notOwner is the name of the error
error fundMe__notOwner();

contract FundMe {
    uint256 funderIndex;
    uint256 public constant MINIMUM_VALUE_USD = 5e18; //Variables declared as constant are set at the time of compilation and cannot be changed afterward.
    address[] public listOfAddressSentMoney;
    //Mappings Are Like Hash Tables key to value
    mapping(address addressOfSender => uint256 amountSent)
        public addressToAmountSent; //This line means that for each address key, there’s an associated uint256 value.
    address public immutable i_owner; //Variables declared as immutable are set once, but only at deployment time, and cannot be changed afterward.
    AggregatorV3Interface private s_priceFeed;

    //Revert: If the condition is true (the sender is not the owner), the transaction is reverted using the revert keyword, and the notOwner() error is triggered.
    modifier CheckIfItsOwner() {
        if (msg.sender != i_owner) {
            revert fundMe__notOwner();
        }
        // require(msg.sender == i_owner, "The address of msg.sender must be qual to the owner");
        _; //Continues to function execution if the require passes
    }

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function getFunds() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_VALUE_USD,
            "If the value is less than required then pop this message"
        );
        listOfAddressSentMoney.push(msg.sender);
        addressToAmountSent[msg.sender] =
            addressToAmountSent[msg.sender] +
            msg.value;
    }

    function withdraw() public CheckIfItsOwner {
        for (
            funderIndex = 0;
            funderIndex < listOfAddressSentMoney.length;
            funderIndex++
        ) {
            address funder = listOfAddressSentMoney[funderIndex];
            addressToAmountSent[funder] = 0; //This sets the amount sent by each address to 0, "withdrawing" their funds.
        }

        listOfAddressSentMoney = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //This function is designed to handle plain Ether transfers (without any data) to the contract.
    //Visibility: external means that it can only be called from outside the contract, which is standard for receive().
    receive() external payable {
        getFunds();
    }

    //This function is used as a catch-all function that gets triggered when the contract:
    //Receives Ether along with data, or attempts to call a function that doesn’t exist in the contract.
    fallback() external payable {
        getFunds();
    }
}
