//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Raffle Contract
 * @author Leticia Azevedo
 * @notice This contract is for creating a sample of an automatic Raffle contract, users can enter a raffle by sending ETH and
 *         the contract automatically will randomly select a winner using Chainlink VRF.
 * @dev Implements Chainlink VRFv2.5 and Keepers
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol"; //Base contract that gives your contract access to the fulfillRandomWords() callback
import {VRFV2PlusClient} from "@chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol"; // Library that provides helper functions for VRF requests, that builds the request in memory (RandomWordsRequest struct + encoding extraArgs)
import {IVRFCoordinatorV2Plus} from "@chainlink/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol"; // Interface to talk to the actual Chainlink Coordinator contract deployed on-chain. which allows us to request random words.
import {AutomationCompatibleInterface} from "@chainlink/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // Custom Errors
    error Raffle__NotEnoughEthSent();
    error Raffle__transferFailed();
    error Raffle__CalculatingRaffle();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    enum RaffleState {
        //enum can also be uint256
        OPEN, //state 0
        CALCULATING //1
    }

    // State variables
    address payable[] private s_players; // Array to store players' addresses
    address payable private s_recentWinner;
    RaffleState private s_raffleState; //start with OPEN state
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp; //this will be a number that represents the last time the raffle was drawn

    // Chainlink VRF related variables
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator; // what is that vrf? is the interface to the Chainlink VRF Coordinator contract
    bytes32 private immutable i_keyHash; // gas lane
    uint256 private immutable i_subscriptionId; // subscription ID for the VRF Coordinator
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations the Chainlink VRF Coordinator waits before responding to a request
    uint32 private immutable i_callbackGasLimit; // Gas limit for the callback function that receives the random words
    uint32 private constant NUM_WORDS = 1; // Number of random words to request, since only one winner is picked Number of words is set to 1

    //events
    event RaffleEntered(address indexed player, uint256 amount); // enterRaffle() emits this event when a player enters the raffle
    event WinnerPicked(address indexed winner); // fulfillRandomWords() emits this event when a winner is picked
    event RequestedRaffleWinner(uint256 indexed requestId); // performUpkeep() emits this event when a request for random words is made

    //contructor also has the VRFConsumerBaseV2Plus constructor, which takes the VRF Coordinator address as an argument
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        // Initialize state variables
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        // Initialize VRF variables
        i_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CalculatingRaffle();
        }
        //require(msg.value >= i_entranceFee, "Not enough ETH sent");
        // require(msg.value >= i_entranceFee, Raffle__NotEnoughEthSent());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }

        s_players.push(payable(msg.sender)); //add the player to the players array
        emit RaffleEntered(msg.sender, msg.value);
    }

    // Function to check if requesting a winner is needed, if yes will run performUpkeep by Chainlink Keepers
    // This function is only used by Chainlink to know when to call performUpkeep()
    // It checks if the raffle: is currently open, enough time has passed, if there are any players, and if the contract has a balance
    // The function is public view, meaning it can be called externally to check the state of the raffle
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); //check if enough time has passed since the last raffle
        bool hasPlayers = s_players.length > 0; //check if there are players in the raffle
        bool hasBalance = address(this).balance > 0; //check if the contract has a balance to pay the winner
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // It returns a boolean indicating true or false if upkeep is needed and a bytes array for performData
        // performData is not used in this case, so we return an empty bytes array
    }

    // Function called by Chainlink Keepers when upkeepNeeded returns true, this is the function that Chainlink Keepers will call to perform the upkeep
    // If upkeep is needed, it changes the raffle state to CALCULATING and requests random words from the VRF Coordinator
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep(""); // other require(upkeepNeeded, "Upkeep not needed");

        // log linkBal to confirm it’s > 0

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        // If upkeep is needed, it changes the raffle state to CALCULATING and requests random words from the VRF Coordinator
        s_raffleState = RaffleState.CALCULATING;

        // Request random words from the VRF Coordinator
        // The request is built using the VRFV2PlusClient library, which encodes the request parameters in a memory struct
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinner(requestId); // The requestId is emitted as an event for tracking purposes
    }

    //CEI rule: check-effects-interactions
    //checks are the conditions that must be met before executing the function
    //effects are the internal changes made to the contract state
    //interactions are the external calls made to other contracts or addresses

    // Basically a pickWinner function
    //but actually the function that Chainlink VRF calls after we use requestRandomWords and the random words are ready
    // requestId is the ID of the request, and randomWords is an array containing the random numbers generated by Chainlink VRF
    // We can use these random numbers to pick a winner or perform other action
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        //pick a winner from the players array using the random number at index 0
        uint256 indexOfWinner = randomWords[0] % s_players.length; // % s_players.length is used to ensure the index is within the players array bounds
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        // Update all internal state before making any external call
        delete s_players; // Reset the players array, sets the length of the array to 0. cheaper gas
        // s_players = new address payable[](0); // Initialize a new empty array, technically replaces the previous array in storage with a new one of length 0. Slightly more gas-expensive
        s_lastTimeStamp = block.timestamp; // Update the last time stamp to reinitialize the raffle
        s_raffleState = RaffleState.OPEN; // Reset the raffle state to OPEN

        emit WinnerPicked(winner);

        // Transfer the prize to the winner
        (bool success, ) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__transferFailed();
        }
    }

    // Getter Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index]; // returns the player at a specific index
    }

    function getPlayers() public view returns (address payable[] memory) {
        return s_players; // returns the entire array of players
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval; // get the raffle interval
    }

    function getTimeUntilNextDraw() public view returns (uint256) {
        if (s_raffleState != RaffleState.OPEN) return 0; // If the raffle is not open, return 0 no time until next draw
        uint256 nextDraw = s_lastTimeStamp + i_interval; // e.g. 1000 + 30 = next is 1030
        return block.timestamp >= nextDraw ? 0 : (nextDraw - block.timestamp); // e.g. block.timestamp is now 1020, next is 1030, so return 10
        //block.timestamp is the current time, if it is greater/equal to next return 0
        //otherwise return the difference between next and block.timestamp
    }

    function getNumOfWords() public pure returns (uint32) {
        return NUM_WORDS;
    }

    function getVrfCoordinator() public view returns (address) {
        return address(i_vrfCoordinator);
    }

    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }
}
