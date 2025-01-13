//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; //to use forge script?
import {FundMe} from "../../src/fund-me.sol"; //the originsl contract
import {FundMeScript} from "../../script/FundMe.s.sol"; //the deploy version
import {GetFundsFundMe, WithdrawFundMe} from "../../script/Integrations.s.sol";

contract IntegrationTest is Test {
    FundMe public fundMe;
    FundMeScript deployFundMe;

    uint256 constant ONE_ETH = 1e18;
    uint256 constant USER_INITIAL_BALANCE = 10e18;

    address USER = makeAddr("user"); //makeAddr() is a Foundry utility function that generate a unique Ethereum address.

    //The setUp() function initializes the test environment:
    function setUp() external {
        deployFundMe = new FundMeScript();
        fundMe = deployFundMe.run();
        vm.deal(USER, USER_INITIAL_BALANCE); //vm.deal Foundry cheatcode that allows you to directly set the balance of any address for testing purposes.
    }

    //This test function simulates a user interacting with the FundMe contract
    function testUserCanFundInteractions() public {
        uint256 preUserBalance = address(USER).balance; //The balance of the user before sending funds.
        uint256 preOwnerBalance = address(fundMe.getOwner()).balance; //The balance of the contract owner before the transaction.

        vm.prank(USER);
        fundMe.getFunds{value: ONE_ETH}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

        assert(address(fundMe).balance == 0);
        assertEq(afterUserBalance + ONE_ETH, preUserBalance);
        assertEq(preOwnerBalance + ONE_ETH, afterOwnerBalance);
    }
}
