//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; //Test gives access to assertions and cheatcodes (vm, assertEq, etc.)
import {FundMe} from "../src/fund-me.sol";
import {FundMeScript} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant ONE_ETH = 1e18;
    address USER = makeAddr("user"); //makeAddr() is a Foundry utility function that generate a unique random Ethereum address.
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
        console.log(fundMe.getOwner()); //address that was test deployed
        console.log(msg.sender); //the actualm owner address
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // function test_RevertIf_WithoutEnoughEth() public {
    //     // expectRevert is used in testing to ensure that your smart contract correctly rejects invalid or unauthorized inputs by reverting. It’s like saying:
    //     // "I expect the next line to fail  because it's invalid. If it doesn't fail, the test is broken and something's wrong with my contract logic."
    //     //expectRevert used to test that a specific function call or action in your smart contract fails and reverts as expected.
    //     //If the line fails, the test passes (expected behavior). If the line succeeds, the test fails (unexpected behavior).
    //     vm.expectRevert("!= Insufficient funds sent");
    //     fundMe.getFunds();
    // }

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

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.getFunds{value: ONE_ETH}();

        address funder = fundMe.getAddressOfFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        //so we dont have to repeat this prank user all the time
        vm.prank(USER);
        fundMe.getFunds{value: ONE_ETH}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //this should revert bcs the user funding is not expected to revert only the owner
        vm.prank(USER);
        vm.expectRevert();

        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //getting owners balance
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //HOAX is vm.pran() vm.deal() combined
            hoax(address(i), ONE_ETH);
            fundMe.getFunds{value: ONE_ETH}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //HOAX is vm.pran() vm.deal() combined
            hoax(address(i), ONE_ETH);
            fundMe.getFunds{value: ONE_ETH}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}

//forge test = to run the test file
//Modular deployments
//Modular testings
