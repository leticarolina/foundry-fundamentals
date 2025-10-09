// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {ManualToken} from "../src/ManualToken.sol";

// ===== Re-declare custom errors to use their selectors in expectRevert
error NotOwner();
error ZeroAddress();
error InsufficientBalance();
error InsufficientAllowance();

contract ManualTokenTest is Test {
    // ---- Test actors (addresses) ----
    address owner; // deployer / i_owner
    address leti; // user 1
    address bob; // user 2
    address router; // pretend "spender" contract (like Uniswap's router)

    // ---- Constants ----
    uint256 constant INITIAL_SUPPLY = 1_000 ether; // 1000 MT with 18 decimals
    uint256 constant TEN = 10 ether;

    ManualToken token; //CUT (Contract Under Test)

    // ---- Re-declare events so we can expectEmit with matching signature ----
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        // Create deterministic, labeled addresses for readability in traces
        owner = makeAddr("owner");
        leti = makeAddr("leticia");
        bob = makeAddr("bob");
        router = makeAddr("router");

        // Deploy the token as `owner` so i_owner = owner
        vm.prank(owner);
        token = new ManualToken(INITIAL_SUPPLY);
    }

    // ============ CONSTRUCTOR / METADATA ============

    function test_constructor_MintsInitialSupplyToOwner() public view {
        // Expect: total supply equals initial supply and owned by deployer
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_metadata_NameSymbolDecimals() public view {
        // Expect: the hardcoded metadata matches the contract
        assertEq(token.name(), "Manual Token");
        assertEq(token.symbol(), "MT");
        assertEq(token.decimals(), 18);
    }

    // ============ TRANSFERS ============

    function test_transfer_UpdatesBalances_EmitsTransfer() public {
        // Pre: owner has INITIAL_SUPPLY, leti has 0
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(leti), 0);

        // Expect the Transfer event (indexed from/to + amount)
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, leti, TEN);

        // Act as owner and transfer TEN to leti
        vm.prank(owner);
        bool success = token.transfer(leti, TEN);
        assertTrue(success);

        // Post: owner decreased, leti increased
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - TEN);
        assertEq(token.balanceOf(leti), TEN);
        // Invariant: totalSupply unchanged by transfers
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_transfer_RevertsWhen_ToIsZeroAddress() public {
        // Attempt transfer to zero address should revert with ZeroAddress()
        vm.prank(owner);
        vm.expectRevert(ZeroAddress.selector);
        token.transfer(address(0), 1);
    }

    function test_transfer_RevertsWhen_InsufficientBalance() public {
        // Leti starts with 0. Trying to send anything must revert
        vm.prank(leti);
        vm.expectRevert(InsufficientBalance.selector);
        token.transfer(bob, 1);
    }

    // ============ APPROVE / ALLOWANCE / TRANSFERFROM ============

    function test_approve_SetsAllowance_EmitsApproval() public {
        // Expect the Approval event
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, router, TEN);

        // Owner approves router to spend TEN
        vm.prank(owner);
        bool ok = token.approve(router, TEN);
        assertTrue(ok);

        // Check stored allowance
        assertEq(token.allowance(owner, router), TEN);
    }

    function test_approve_RevertsWhen_SpenderZeroAddress() public {
        // Public approve checks spender != 0 via _approve
        vm.prank(owner);
        vm.expectRevert(ZeroAddress.selector);
        token.approve(address(0), TEN);
    }

    function test_increaseAllowance_IncreasesByDelta() public {
        // Start by approving a base amount
        vm.startPrank(owner);
        token.approve(router, 1 ether);

        // Increase by +2 => total 3
        bool ok = token.increaseAllowance(router, 2 ether);
        vm.stopPrank();
        assertTrue(ok);
        assertEq(token.allowance(owner, router), 3 ether);
    }

    function test_decreaseAllowance_DecreasesAnd_RevertsBelowZero() public {
        // Set allowance to 2
        vm.startPrank(owner);
        token.approve(router, 2 ether);

        // Decrease by 1 -> expect 1
        bool ok1 = token.decreaseAllowance(router, 1 ether);
        assertTrue(ok1);
        assertEq(token.allowance(owner, router), 1 ether);

        // Decrease by 2 -> should revert (below zero)
        vm.expectRevert(InsufficientAllowance.selector);
        token.decreaseAllowance(router, 2 ether);
        vm.stopPrank();
    }

    function test_transferFrom_ConsumesAllowance_MovesFunds() public {
        // 1) Owner -> Leti: send her TEN tokens so she has balance to be spent
        vm.prank(owner);
        token.transfer(leti, TEN);
        assertEq(token.balanceOf(leti), TEN);

        // 2) Leti approves router to spend TEN
        vm.prank(leti);
        token.approve(router, TEN);
        assertEq(token.allowance(leti, router), TEN);

        // 3) Router spends 3 from Leti -> to Bob using transferFrom
        vm.prank(router);
        bool ok = token.transferFrom(leti, bob, 3 ether);
        assertTrue(ok);

        // Expect: Leti balance decreased, Bob increased, allowance decreased
        assertEq(token.balanceOf(leti), TEN - 3 ether);
        assertEq(token.balanceOf(bob), 3 ether);
        assertEq(token.allowance(leti, router), TEN - 3 ether);

        // Supply invariant: unchanged
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_transferFrom_RevertsWhen_InsufficientAllowance() public {
        // Give Leti some funds first
        vm.prank(owner);
        token.transfer(leti, TEN);

        // Leti approves only 1 ether
        vm.prank(leti);
        token.approve(router, 1 ether);

        // Router tries to spend 2 ether -> should revert InsufficientAllowance
        vm.prank(router);
        vm.expectRevert(InsufficientAllowance.selector);
        token.transferFrom(leti, bob, 2 ether);
    }

    // ============ MINT / BURN (OWNER-ONLY) ============

    function test_mint_OnlyOwner_CanMint_IncreasesSupply_EmitsTransfer()
        public
    {
        // Non-owner tries to mint -> revert NotOwner
        vm.prank(leti);
        vm.expectRevert(NotOwner.selector);
        token.mint(leti, TEN);

        // Owner mints to Bob -> expect Transfer(0x0 -> bob, TEN)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), bob, TEN);

        vm.prank(owner);
        token.mint(bob, TEN);

        // Balances + supply increased
        assertEq(token.balanceOf(bob), TEN);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + TEN);
    }

    function test_mint_RevertsWhen_ToZeroAddress() public {
        // Minting to zero address forbidden -> ZeroAddress
        vm.prank(owner);
        vm.expectRevert(ZeroAddress.selector);
        token.mint(address(0), TEN);
    }

    function test_burn_OnlyOwner_CanBurn_DecreasesSupply_EmitsTransfer()
        public
    {
        // Give Leti 10 so we can burn from her balance
        vm.prank(owner);
        token.transfer(leti, TEN);
        assertEq(token.balanceOf(leti), TEN);

        // Non-owner tries to burn -> NotOwner
        vm.prank(leti);
        vm.expectRevert(NotOwner.selector);
        token.burn(leti, 1 ether);

        // Owner burns 6 from Leti -> expect Transfer(leti -> 0x0, 6)
        vm.expectEmit(true, true, false, true);
        emit Transfer(leti, address(0), 6 ether);

        vm.prank(owner);
        token.burn(leti, 6 ether);

        // Balances: Leti decreased; supply decreased
        assertEq(token.balanceOf(leti), 4 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 6 ether);
    }

    function test_burn_RevertsWhen_InsufficientBalance() public {
        // Leti has 0 right now; burning > 0 must fail
        vm.prank(owner);
        vm.expectRevert(InsufficientBalance.selector);
        token.burn(leti, 1);
    }

    // ============ INVARIANTS / PROPERTIES ============

    function test_transfers_ConserveTotalSupply() public {
        // Move tokens around, supply must remain INITIAL_SUPPLY
        vm.startPrank(owner);
        token.transfer(leti, 123);
        token.transfer(bob, 456);
        vm.stopPrank();

        vm.prank(leti);
        token.transfer(bob, 100);

        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // Simple fuzz: any amount bounded by owner's balance should keep supply constant after transfer
    // function testFuzz_transfer_PreservesSupply(address to, uint256 amt) public {
    //     // Bound recipient: not zero to avoid ZeroAddress revert
    //     to = bound(to, address(1), address(type(uint160).max));
    //     // Bound amount by owner's current balance
    //     uint256 ownerBal = token.balanceOf(owner);
    //     amt = bound(amt, 0, ownerBal);

    //     uint256 preSupply = token.totalSupply();

    //     vm.prank(owner);
    //     token.transfer(to, amt);

    //     // Supply unchanged
    //     assertEq(token.totalSupply(), preSupply);
    // }
}
