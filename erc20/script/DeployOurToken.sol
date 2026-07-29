// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployOurToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (Token) {
        vm.startBroadcast();
        Token ot = new Token("Tokenito", "TITO");
        vm.stopBroadcast();

        return ot;
    }
}
