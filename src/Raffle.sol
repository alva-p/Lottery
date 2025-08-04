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

import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author alva-p
 * @notice This contract is for creating a sample raffle system.
 * @dev Implements Chainling VRFv2.5
 */
contract Raffle is VRFV2PlusWrapperConsumerBase {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();

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
    ) VRFV2PlusWrapperConsumerBase(_vrfV2PlusWrapper) {
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

    //1. Get a random number
    //2. Use the random number to pick a winner
    //3. Be automatically called
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING; // Set the raffle state to CALCULATING
        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest(
            {
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            }
        );
    
        (uint256 requestId, ) = requestRandomness(
            i_callbackGasLimit,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS,
            VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        );    }


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
}
