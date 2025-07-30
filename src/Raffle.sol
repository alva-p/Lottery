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
    error Raffle_SendMoreToEnterRaffle();

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

    //Events

    event RaffleEnter(address indexed player);

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
    }

    function enterRaffle() external payable {
        //require(msg.value >= i_entranceFee, "Not enough ETH sent to enter the raffle");
        if (msg.value < i_entranceFee) {
            revert Raffle_SendMoreToEnterRaffle();
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
        // Get our random number 2.5
        // 1. Request RNG
        // 2. Get

        uint32 callbackGasLimit = i_callbackGasLimit;
        uint16 requestConfirmations = REQUEST_CONFIRMATIONS;
        uint32 numWords = NUM_WORDS;
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}));

        (uint256 requestId,) = requestRandomness(callbackGasLimit, requestConfirmations, numWords, extraArgs);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {}

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
