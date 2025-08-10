// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    //mock player
    address public PLAYER = makeAddr("player_leticia");
    uint256 public STARTING_BALANCE = 1 ether;

    // mock variables
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    uint256 account;

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
        account = config.account; // get the account from the config

        // VRFCoordinatorV2_5Mock coord = VRFCoordinatorV2_5Mock(vrfCoordinator); //
        // coord.fundSubscription(subscriptionId, 4 ether); // give it a big balance (mock units)
        vm.deal(PLAYER, STARTING_BALANCE); // give ETH to player
    }

    //modifier to enter the raffle and warp/foward time so that checkUpkeep returns true
    modifier raffleEntredAndTimePassed() {
        // STEP 1: Player enters Raffle
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // STEP 2: Fast-forward time and block number
        vm.warp(block.timestamp + interval + 1); // moves time forward so upkeep is valid, (need this so checkUpkeep() returns true)
        //skip(31); //also moves the block.timestamp 31 seconds forward
        vm.roll(block.number + 1); // advances block height
        //Together, they "fool" the contract into thinking time has passed naturally, so it can perform upkeep.
        _;
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

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating()
        public
        raffleEntredAndTimePassed
    {
        // after the player enters the raffle and time has passed, the raffle state should be CALCULATING
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
    /*//////////////////////////////////////////////////////////////
                          PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/
    function testPerformUpkeepCanOnlyBeCalledIfCheckUpkeepReturnsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepReturnsFalse() public {
        uint256 currentBalance = 0; // no one has entered the raffle yet, so balance is 0
        uint256 currentPlayers = 0; // no players have entered yet
        Raffle.RaffleState currentRaffleState = raffle.getRaffleState(); // should be OPEN

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector, // passing the 3 parameters that the error requires
                currentBalance,
                currentPlayers,
                uint256(currentRaffleState)
            )
        );
        raffle.performUpkeep(""); // this should REVERT since checkUpkeep() would return false
    }

    //advanced test, because it checks the event emitted by performUpkeep and uses vm.recordLogs() to get the requestId
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        vm.recordLogs(); // this tells Foundry: “start capturing all EVM logs (events) emitted until I call vm.getRecordedLogs().” it record all the logs that happen during the next call
        raffle.performUpkeep(""); // calls the VRF coordinator mock → that mock emits its own events (e.g., RandomWordsRequested) , my contract emits RequestedRaffleWinner(requestId)

        //vm.getRecordedLogs() returns an array of all logs emitted during that call (both from my contract and from the coordinator mock).
        Vm.Log[] memory entries = vm.getRecordedLogs(); // get the recorded logs on the last call
        bytes32 lastEntryRequestId = entries[1].topics[1]; // topics is the array of indexed parameters, so we get the second topic which is the requestId, topics[0] is the event signature, topics[1] is the first indexed parameter, etc.
        //Why entries[1]? Because the first log (entries[0]) is usually from the VRF mock (RandomWordsRequested), and the second log (entries[1]) is from my contract (RequestedRaffleWinner).

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState(); // get the new raffle state
        assert(bytes32(lastEntryRequestId) > 0); // assert that the requestId is greater than 0, meaning it was emitted
        assert(uint256(raffleState) == 1); // assert that the requestId is 1, meaning it was emitted
    }

    /*//////////////////////////////////////////////////////////////
                          FULLFILL RANDOM WORDS
    //////////////////////////////////////////////////////////////*/
    modifier skipFork() {
        if (block.chainid != CodeConstants.LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }
    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntredAndTimePassed skipFork {
        //this is using a manually generated random requestId
        //A valid requestId exists only after raffle calls performUpkeep() and the coordinator accepts the request.
        //here we are testing that fulfillRandomWords() can only be called after performUpkeep() has been called and performUpkeep() has not been called yet
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            0, // requestId
            address(raffle) // consumer address
        );

        //this is using a random requestId, fuzzing the input
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId, //this is a random requestId
            address(raffle) // consumer address
        );
    }

    // function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
    //     public
    //     raffleEntredAndTimePassed
    // {
    //     // Arrange

    //     uint256 additionalEntrants = 3; //4 players in total
    //     uint256 startingIndex = 1; // start from index 1 because index 0 is the PLAYER
    //     address expectedWinner = address(1);

    //     for (
    //         uint256 i = startingIndex;
    //         i < startingIndex + additionalEntrants;
    //         i++
    //     ) {
    //         address player = address(uint160(i)); //create a new player address and convert it to address type
    //         hoax(player, STARTING_BALANCE); //hoax will send 10 ether each to the player address
    //         raffle.enterRaffle{value: entranceFee}(); // each player enters the raffle
    //     }
    //     uint256 winnerStartingBalance = expectedWinner.balance; //
    //     uint256 startingTimeStamp = raffle.getLastTimeStamp(); // get the starting timestamp before we warp time

    //     // Act
    //     vm.recordLogs();
    //     raffle.performUpkeep(""); // emits requestId
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bytes32 requestId = entries[1].topics[1];

    //     // Pretend to be Chainlink VRF
    //     VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
    //         uint256(requestId),
    //         address(raffle)
    //     );

    //     // Assert
    //     address recentWinner = raffle.getRecentWinner();
    //     Raffle.RaffleState raffleState = raffle.getRaffleState();
    //     uint256 winnerBalance = recentWinner.balance;
    //     uint256 endingTimeStamp = raffle.getLastTimeStamp(); // get the ending timestamp after the winner is picked
    //     uint256 prize = entranceFee * (additionalEntrants + 1); //prize is the entrance fee multiplied by the number of players (including the PLAYER) entranceFee * 4

    //     assert(expectedWinner == recentWinner);
    //     assert(uint256(raffleState) == 0);
    //     assert(winnerBalance == winnerStartingBalance + prize);
    //     assert(endingTimeStamp > startingTimeStamp);
    // }
}
