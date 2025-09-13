// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";



contract DeployRaffle is Script{
    function run() public {}
        // Deploy the Raffle contrac}

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        // local deploys mock, get local config
        // get sepolia config
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            networkConfig.entranceFee,
            networkConfig.interval,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }

    }

    //function deployContract() public returns(Raffle, HelperConfig) {}

