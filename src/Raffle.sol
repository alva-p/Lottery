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

import {VRFConsumerBaseV2} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
// Import the correct VRF wrapper base contract
/**
 * @title A sample Raffle contract
 * @author alva-p
 * @notice This contract is for creating a sample raffle system.
contract Raffle is VRFV2WrapperConsumerBase {
 */
contract Raffle is VRFConsumerBaseV2 {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle_UpkeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN, // 0 
        CALCULATING // 1 
    }


    /*State variables */
    uint256 private immutable i_entranceFee;
    // @dev The duration of the raffle in seconds.
    uint256 private immutable i_interval; //Interval for picking a winner
    address payable[] private s_players; //Array for storing players
    uint256 private s_lastTimeStamp; //Last time a winner was picked
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1; //Number of random words to request
    address private s_recentWinner; //Address of the most recent winner
    RaffleState private s_raffleState;

    //Events

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfV2PlusWrapper,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(_vrfV2PlusWrapper) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_raffleState = RaffleState.OPEN; // Initialize the raffle state to OPEN
    }

    function enterRaffle() external payable {
        //require(msg.value >= i_entranceFee, "Not enough ETH sent to enter the raffle");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen(); // Raffle is not open
        }


        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }


    // When should the winner be picked?
    /**
     * @dev This is the function that the chainlink nodes will call to see if the loterry is ready to have a winner picked.
     * The following should be true in ordenr ofr upkeppNeeded to be true: 
     * 1- The time interval has passed between raffle runs
     * 2- The lottery is open 
     * 3- The contract has ETH
     * 4- Implicity, your subscription has LINK
     * @param  - ignored
     * @return upkeepNeeded - true if its time to restart the lottery
     * @return - ignored 
     */
    function checkUpkeep(bytes memory /* checkData */) 
        public 
        view  
        returns (bool upkeepNeeded, bytes memory /* performData */)  /* time to pick winner? */

    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance >0 ;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers; // %% == and
        return (upkeepNeeded, "");

    }

    //1. Get a random number
    //2. Use the random number to pick a winner
    //3. Be automatically called
    function performUpkeep() external {
        (bool upkeepNeeded, ) = checkUpkeep(""); // Check if upkeep is needed
        if(!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING; //      the raffle state to CALCULATING
        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get
    }
    

    // CEI: checks, effects, interactions patterns
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
        // CHECKS


        //INTERACTIONS (internal contract state)
        uint256 indexOfWinner = _randomWords[0] & s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // Reset the players array
        s_lastTimeStamp = block.timestamp; // Update the last timestamp 
        emit WinnerPicked(s_recentWinner);

        // INTERACTIONS (external contract state)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success){
            revert Raffle__TransferFailed();
        }
    }


    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
}
