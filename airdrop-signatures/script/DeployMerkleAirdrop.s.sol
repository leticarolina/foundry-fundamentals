// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BlackBean} from "../src/BlackBean.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    MerkleAirdrop public merkleAirdrop;
    BlackBean public blackBean;
    bytes32 public ROOT =
        0x943b3c6ac3580cdba39002a0d542b36497d89ab564419fdc318827270ebc2e74;
    uint256 public INITIAL_MINT = 100e18;

    function run() external returns (MerkleAirdrop, BlackBean) {
        return deploy();
    }

    function deploy() public returns (MerkleAirdrop, BlackBean) {
        vm.startBroadcast();
        blackBean = new BlackBean(); //Deploys ERC-20 token
        merkleAirdrop = new MerkleAirdrop(ROOT, IERC20(address(blackBean))); //Passes the Merkle root and the ERC-20 token address into the constructor
        blackBean.mint(blackBean.owner(), INITIAL_MINT); //Mints 100 tokens to the owner (deployer wallet)
        blackBean.transfer(address(merkleAirdrop), INITIAL_MINT); //sends them all to the MerkleAirdrop contract so it has funds to distribute.
        vm.stopBroadcast();

        return (merkleAirdrop, blackBean);
    }
}
