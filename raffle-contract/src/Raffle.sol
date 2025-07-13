//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Raffle Contract
 * @author Leticia Azevedo
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
import {VRFCoordinatorV2Interface} from "@chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    // Custom Errors
    error Raffle__NotEnoughEthSent();

    uint256 leticia;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    // address vrfCoordinator;

    //events
    event RaffleEntered(address indexed player, uint256 amount);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        // vrfCoordinator = vrfCoordinator;
    }

    function enterRaffle() public payable {
        //require(msg.value >= i_entranceFee, "Not enough ETH sent");
        // require(msg.value >= i_entranceFee, Raffle__NotEnoughEthSent());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        emit RaffleEntered(msg.sender, msg.value);
    }

    function pickWinner() public view {
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            //revert here ;
        }
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {}
    // This function is called by the VRF Coordinator when it has a random number for us
    // requestId is the ID of the request, and randomWords is an array of random numbers
    // We can use these random numbers to pick a winner or perform other acti

    // Getter Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
