//SPDX-License-Identifier:MIT
//fund
//withdraw

pragma solidity ^0.8.18;
//Scripts are used to deploy contracts, call contract functions, or perform on-chain actions through Foundry's forge script command.
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/fund-me.sol";

//contract for funding the FundMe contract
contract GetFundsFundMe is Script {
    uint256 constant ONE_ETH = 0.1 ether;

    function getFundsFundMe(address mostRecentDeploy) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeploy)).getFunds{value: ONE_ETH}();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentDeploy = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        getFundsFundMe(mostRecentDeploy);
    }
}
//contract for withdrawing funds from the FundMe contract
contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentDeploy) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeploy)).withdraw();
        vm.stopBroadcast();
        console.log("Withdraw FundMe balance!");
    }

    function run() external {
        address mostRecentDeploy = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );

        withdrawFundMe(mostRecentDeploy);
    }
}
