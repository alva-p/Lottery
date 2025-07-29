// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;



/**
 * @title A sample Raffle contract
 * @author alva-p 
 * @notice This contract is for creating a sample raffle system.
 * @dev Implements Chainling VRFv2.5
 */

contract Raffle {
    /* Errors */
    error Raffle_SendMoreToEnterRaffle();
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }
    
    function enterRaffle() public payable{
        //require(msg.value >= i_entranceFee, "Not enough ETH sent to enter the raffle");
        if(msg.value < i_entranceFee) {
            revert Raffle_SendMoreToEnterRaffle();
        }

    }

    function pickWinner() public {}

    /**Getter Functions*/

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }



 

}

