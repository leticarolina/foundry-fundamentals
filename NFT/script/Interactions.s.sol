// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {LeticiaNFT} from "../src/BasicNft.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract MintBasicNft is Script {
    // string public constant TOKENURI =
    //     "ipfs://QmUJeMau6ywH4ff3kPRtE23hVr3Xw8hhW4aLbt4uqAzVNv";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "LeticiaNFT",
            block.chainid
        );

        mintNftOnContract(mostRecentlyDeployed);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        LeticiaNFT(contractAddress).mintNft();
        vm.stopBroadcast();
    }
}
