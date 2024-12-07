//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/fund-me.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    //here testing if the variable MINIMUM_VALUE_USD is actually returning 5
    //ps: need to check the variable to the function
    //assertEq() is sort of require()
    function testCheckMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_VALUE_USD(), 5e18);
    }

    //checking if the sender of the contract will be set to the owner
    function testIsTheContractOwner() public {
        // forge test -vv  the number of console.log we want to return
        console.log(fundMe.i_owner()); //address that was test deployed
        console.log(msg.sender); //the actualm owner address
        assertEq(fundMe.i_owner(), address(this));
    }
}

//forge test = to run the test file
//Modular deployments
//Modular testings
