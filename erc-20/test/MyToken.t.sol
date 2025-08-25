// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {DeployMyToken} from "../script/DeployMyToken.s.sol";

contract CounterTest is Test {
    MyToken public myToken;
    DeployMyToken public deploy;
    address leti = makeAddr("leticia");
    uint256 public FUNDS = 10 ether;

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        deploy = new DeployMyToken();
        myToken = deploy.run();
        vm.prank(msg.sender);
        myToken.transfer(leti, FUNDS);
    }

    function test_leti_InitialBalance() public view {
        assertEq(myToken.balanceOf(leti), FUNDS);
    }

    function test_nameSymbolDecimals() public view {
        assertEq(myToken.name(), "MyToken");
        assertEq(myToken.symbol(), "MT");
        assertEq(myToken.decimals(), 18);
    }

    function test_allowances() public {
        uint256 initialAllowance = 100;
        uint256 transferAmount = 10;
        address bob = makeAddr("bob");
        //I allow bob to spend my tokens
        vm.prank(leti);
        myToken.approve(bob, initialAllowance);

        vm.prank(bob);
        myToken.transferFrom(leti, bob, transferAmount);
        assert(myToken.balanceOf(bob) == transferAmount);
        assert(myToken.balanceOf(leti) == FUNDS - transferAmount);
    }
}
