//SPDX-License-Identifier: MIT
//https://book.getfoundry.sh/tutorials/best-practices#scripts
pragma solidity 0.8.18;

//importing this for it to use the functionalities foundry has as a script
import {Script} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

//essentially creating a contract to deploy our actual simple storage contract.
//here will be solidity scripting language rather than contract language
contract DeploySimpleStorage is Script {
    //every script need a main function, per usual called "run", so whenever we run "forge script" this function will be called
    //run is an external function that will return the Simple Storage contract
    function run() external returns (SimpleStorage) {
        //starting point for the list of transactions that will be sent to RPC URL;
        //ps: vm is specific for foundry (cheat code)
        vm.startBroadcast();

        SimpleStorage scriptSimpleStorage = new SimpleStorage();
        //ending point same as starting
        vm.stopBroadcast();
        return scriptSimpleStorage;
    }
}

//Running on the terminal
//forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key xxxx

//when it return "ONCHAIN EXECUTION COMPLETE AND SUCESSFUL"
