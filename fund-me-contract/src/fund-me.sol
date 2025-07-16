//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Converter} from "./Converter.sol";
import {AggregatorV3Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

using Converter for uint256;

// you can define custom errors to provide meaningful descriptions for conditions that fail in your smart contract
//error is the keyword used to define a custom error.
//notOwner is the name of the error
error fundMe__notOwner();
//0xA0C579D3B828271f5255464083BaE3e004a64828 deployed and verified on Sepolia
contract FundMe {
    uint256 funderIndex;
    uint256 public constant MINIMUM_VALUE_USD = 5e18; //Variables declared as constant are set at the time of compilation and cannot be changed afterward.
    address[] private s_listOfAddressSentMoney; //The s_ prefix stands for storage variables, which are written to or read from the Ethereum blockchain's persistent storage.
    //Mappings Are Like Hash Tables key to value
    mapping(address addressOfSender => uint256 amountSent)
        private s_addressToAmountSent; //This line means that for each address key, there’s an associated uint256 value.
    address private immutable i_owner; //Variables declared as immutable are set once, but only at deployment time, and cannot be changed afterward.
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
        s_listOfAddressSentMoney.push(msg.sender);
        s_addressToAmountSent[msg.sender] =
            s_addressToAmountSent[msg.sender] +
            msg.value;
    }
    //reading loop from storage, more expensive than reading from memory
    // function withdraw() public CheckIfItsOwner {
    //     for (
    //         funderIndex = 0;
    //         funderIndex < s_listOfAddressSentMoney.length;
    //         funderIndex++
    //     ) {
    //         address funder = s_listOfAddressSentMoney[funderIndex];
    //         s_addressToAmountSent[funder] = 0; //This sets the amount sent by each address to 0, "withdrawing" their funds.
    //     }

    //     s_listOfAddressSentMoney = new address[](0);

    //     (bool callSuccess, ) = payable(msg.sender).call{
    //         value: address(this).balance
    //     }("");
    //     require(callSuccess, "Call failed");
    // }

    function withdraw() public CheckIfItsOwner {
        uint256 fundersLength = s_listOfAddressSentMoney.length;
        for (funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_listOfAddressSentMoney[funderIndex];
            s_addressToAmountSent[funder] = 0; //This sets the amount sent by each address to 0, "withdrawing" their funds.
        }

        s_listOfAddressSentMoney = new address[](0);

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

    // view/pure functions (getters)
    // Getter function to access the private mapping since the mapping is declared as private it wont have a getter function automatically
    //because your drawer (the mapping) is private, no one can open it directly from outside the contract.
    //It takes one input: fundingAddress (the address of the sender you want to look up). view: This tells Solidity that the function only reads data (it doesn’t change anything in the contract).
    function getAddressToAmountToAmountSent(
        address fundingAddress
    ) external view returns (uint256) {
        //This is where the function goes into the private mapping (s_addressToAmountSent), finds the value stored for the fundingAddress, and gives it back.
        return s_addressToAmountSent[fundingAddress];
        //example to call this function: uint256 amount = fundMe.getAddressToAmountSent(0xDE...456);
    }

    //taking an index and returning an address
    // This function lets external users or contracts retrieve the address of a funder by specifying their position (index) in the array.
    //example using address funder = fundMe.getAddressOfFunder(1);
    function getAddressOfFunder(uint256 index) external view returns (address) {
        return s_listOfAddressSentMoney[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
