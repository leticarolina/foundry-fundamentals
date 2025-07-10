//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Raffle Contract
 * @author Leticia Azevedo
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

contract Raffle {
    // Custom Errors
    error Raffle__NotEnoughEthSent();

    uint256 leticia;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    //events
    event RaffleEntered(address indexed player, uint256 amount);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        //require(msg.value >= i_entranceFee, "Not enough ETH sent");
        // require(msg.value >= i_entranceFee, Raffle__NotEnoughEthSent());
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        emit RaffleEntered(msg.sender, msg.value);
    }

    function pickWinner() public {
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            //revert here ;
        }
    }

    // Getter Functions
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
