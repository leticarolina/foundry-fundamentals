//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Raffle Contract
 * @author Leticia Azevedo
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
// import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol"; //Base contract that gives your contract access to the fulfillRandomWords() callback
import {VRFV2PlusClient} from "@chainlink/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol"; // Library that provides helper functions for VRF requests, that builds the request in memory (RandomWordsRequest struct + encoding extraArgs)
import {IVRFCoordinatorV2Plus} from "@chainlink/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol"; // Interface to talk to the actual Chainlink Coordinator contract deployed on-chain. which allows us to request random words.

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
        OPEN, //0
        CALCULATING //1
    }

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    // Chainlink VRF related variables
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator; // what is that vrf? is the interface to the Chainlink VRF Coordinator contract
    bytes32 private immutable i_keyHash; // gas lane
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address payable[] private s_players; // Array to store players' addresses
    address payable private s_recentWinner;
    RaffleState private s_raffleState; //start with OPEN state

    //events
    event RaffleEntered(address indexed player, uint256 amount);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        // _vrfCoordinator = i_vrfCoordinator;

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

    //function to check if upkeep is needed
    // This function is called by the Chainlink Keeper to check if upkeep is needed
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval); //check if enough time has passed since the last raffle
        bool hasPlayers = s_players.length > 0; //check if there are players in the raffle
        bool hasBalance = address(this).balance > 0; //check if the contract has a balance to pay the winner
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    //former pickWinner function
    // This function is called by the Chainlink Keeper to check if upkeep is needed
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        // VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
        //     .RandomWordsRequest({
        //         keyHash: i_keyHash,
        //         subId: i_subscriptionId,
        //         requestConfirmations: REQUEST_CONFIRMATIONS,
        //         callbackGasLimit: i_callbackGasLimit,
        //         numWords: NUM_WORDS,
        //         extraArgs: VRFV2PlusClient._argsToBytes(
        //             VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        //         )
        //     });

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
        emit RequestedRaffleWinner(requestId);
        // uint256 requestId = i_vrfCoordinator.requestRandomWords(request);
    }

    //cei rule: check-effects-interactions
    //checks are the conditions that must be met before executing the function
    //effects are the internal changes made to the contract state
    //interactions are the external calls made to other contracts or addresses
    // This function is called by the VRF Coordinator when it has a random number for us
    // requestId is the ID of the request, and randomWords is an array of random numbers
    // We can use these random numbers to pick a winner or perform other action
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        delete s_players; // Reset the players array, sets the length of the array to 0. cheaper gas
        s_players = new address payable[](0); // Initialize a new empty array, Technically replaces the previous array in storage with a new one of length 0. Slightly more gas-expensive
        s_lastTimeStamp = block.timestamp; // Update the last time stamp
        emit WinnerPicked(winner);

        // Transfer the prize to the winner
        (bool success, ) = winner.call{value: address(this).balance}("");
        require(success, "Transfer failed");

        s_raffleState = RaffleState.OPEN; // Reset the raffle state to OPEN
    }

    // Getter Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
