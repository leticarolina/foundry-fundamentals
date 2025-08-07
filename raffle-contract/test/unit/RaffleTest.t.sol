// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    //mock player
    address public PLAYER = makeAddr("player_leticia");
    uint256 public STARTING_BALANCE = 10 ether;

    // mock variables
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;

    //events must be declared in the test file to use them with vm.expectEmit
    event RaffleEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        linkToken = config.token;

        vm.deal(PLAYER, STARTING_BALANCE); // give ETH to player
    }
    /*//////////////////////////////////////////////////////////////
                           ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/
    function test_RaffleStartsOpenState() public view {
        // Check that the raffle state is OPEN or basically the number 0
        //calculating refers to the number 1
        assertEq(
            uint256(raffle.getRaffleState()),
            uint256(Raffle.RaffleState.OPEN)
        );
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // STEP 1: Player enters Raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // STEP 2: Fast-forward time and block number
        vm.warp(block.timestamp + interval + 1); // moves time forward so upkeep is valid, (need this so checkUpkeep() returns true)
        //skip(31); //also moves the block.timestamp 31 seconds forward
        vm.roll(block.number + 1); // advances block height
        //Together, they "fool" the contract into thinking time has passed naturally, so it can perform upkeep.

        // STEP 3: Trigger the state change
        raffle.performUpkeep(""); // this should flip state to CALCULATING

        // STEP 4: Expect a revert if someone tries to enter during CALCULATING
        vm.expectRevert(Raffle.Raffle__CalculatingRaffle.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}(); // this should now REVERT
    }

    function testRaffleRevertsWHenYouDontSendValue() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRevertsWhenYouSendInsufficientEth() public {
        uint256 insufficienteEth = entranceFee - 0.005 ether;

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle{value: insufficienteEth}();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //arrange
        vm.prank(PLAYER);
        //act
        raffle.enterRaffle{value: entranceFee}();
        //assert
        address playerRecorded = raffle.getPlayer(0);
        assertEq(playerRecorded, PLAYER);
    }

    /*//////////////////////////////////////////////////////////////
                           EMIT EVENTS
    //////////////////////////////////////////////////////////////*/
    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        // Act / Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER, entranceFee);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                           CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/
    function testCheckUpkeepReturnsFalseIfContractHasNoBalance() public {
        //arrange
        //assume the time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //act
        // checkUpkeep() is called by the Chainlink Keeper to check if upkeep is needed
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //assert
        // upkeepNeeded should be false because the contract has no balance
        assert(!upkeepNeeded);
    }
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // // STEP 1: Player enters Raffle
        // vm.prank(PLAYER);
        // raffle.enterRaffle{value: entranceFee}();

        // // STEP 2: Fast-forward time and block number
        // skip(31); // moves time forward so upkeep is valid, (need this so checkUpkeep() returns true)
        // vm.roll(block.number + 1); // advances block height
        // //Together, they "fool" the contract into thinking time has passed naturally, so it can perform upkeep.

        // // STEP 3: Trigger the state change
        // raffle.performUpkeep(""); // this should flip state to CALCULATING

        // //step 1,2,3 are arrange, basically entering the raffle and making it calculating state

        // // STEP 4: Check upkeep. It should return false now since raffle is not open anymore
        // (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // assert(!upkeepNeeded);

        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        skip(31);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // this should flip state to CALCULATING
        Raffle.RaffleState raffleState = raffle.getRaffleState(); // state should be CALCULATING now
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep(""); // checkUpkeep() is called by the Chainlink Keeper to check if upkeep is needed

        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING); // raffle state should be CALCULATING
        assert(upkeepNeeded == false); // upkeepNeeded should be false because the raffle is not open anymore
    }
    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        //arrange - player enters raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        skip(28);

        //act - check if checkupkeep returns true but not enough time has passed
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //assert
        assert(upkeepNeeded == false);
    }
    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        //arrange - player enters raffle and ensure enough time has passed
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 5);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assertEq(upkeepNeeded, true);
    }
}
