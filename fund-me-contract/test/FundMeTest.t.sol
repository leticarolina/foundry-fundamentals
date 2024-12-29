//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/fund-me.sol";
import {FundMeScript} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant ONE_ETH = 1e18;
    address USER = makeAddr("user"); //makeAddr() is a Foundry utility function that generate a unique Ethereum address.

    uint256 constant USER_INITIAL_BALANCE = 10e18;

    function setUp() external {
        FundMeScript deployFundMe = new FundMeScript();
        fundMe = deployFundMe.run();
        vm.deal(USER, USER_INITIAL_BALANCE); //vm.deal Foundry cheatcode that allows you to directly set the balance of any address for testing purposes.
        //syntax vm.deal(address, amount);
    }

    //here testing if the variable MINIMUM_VALUE_USD is actually returning 5
    //ps: need to check the variable to the function
    //assertEq() is sort of require()
    function testCheckMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_VALUE_USD(), 5e18);
    }

    //checking if the sender of the contract will be set to the owner
    function testIsTheContractOwner() public view {
        // forge test -vv  the number of console.log we want to return
        console.log(fundMe.i_owner()); //address that was test deployed
        console.log(msg.sender); //the actualm owner address
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testFail_WithoutEnoughEth() public {
        // expectRevert is used in testing to ensure that your smart contract correctly rejects invalid or unauthorized inputs by reverting. It’s like saying:
        // "I expect the next line to fail  because it's invalid. If it doesn't fail, the test is broken and something's wrong with my contract logic."
        //expectRevert used to test that a specific function call or action in your smart contract fails and reverts as expected.
        //If the line fails, the test passes (expected behavior). If the line succeeds, the test fails (unexpected behavior).
        vm.expectRevert("Insufficient funds sent");
        fundMe.getFunds();
    }

    function testFundUpdatesDataStructure() public {
        vm.prank(USER); //the next transaction will be sent by USER aadress
        //This line simulates someone funding the FundMe contract with 1 ETH (in wei).
        fundMe.getFunds{value: ONE_ETH}();
        //Calls the getAddressToAmountToAmountSent function to check how much ETH the current contract (test contract) has sent to fundMe.
        uint256 amountFunded = fundMe.getAddressToAmountToAmountSent(
            address(USER)
        );
        //Using Foundry’s assertEq function to verify that the amountFunded matches 1e18 (1 ETH).
        assertEq(amountFunded, ONE_ETH);
    }
}

//forge test = to run the test file
//Modular deployments
//Modular testings
