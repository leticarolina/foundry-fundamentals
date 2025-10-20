// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    error ClaimAirdrop__InvalidSignatureLength();
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public immutable CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 immutable PROOF_ONE =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 immutable PROOF_TWO =
        0x1bb96f63c531e773ee0e7a465cf042becb72dfee0ba16636e73889917df51885;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];

    bytes private SIGNATURE =
        hex"12e145324b60cd4d302bfad59f72946d45ffad8b9fd608e672fd7f02029de7c438cfa0b8251ea803f361522da811406d441df04ee99c3dc7d65f8550e12be2ca1c";

    function sliptSignature(
        bytes memory sig
    ) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        // require(sig.length == 65, "Wrong sig lenth");
        if (sig.length != 65) {
            revert ClaimAirdrop__InvalidSignatureLength();
        }
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MerkleAirdrop",
            block.chainid
        );
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = sliptSignature(SIGNATURE);
        MerkleAirdrop(mostRecentlyDeployed).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            proof,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }
}

/**
 * deploy contracts 
 * == Return ==
  0: contract MerkleAirdrop 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  1: contract BlackBean 0x5FbDB2315678afecb367f032d93F642f64180aa3  
 * first, get message to sign
 * cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address, uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545
 * 0x39430e4990aa8a1f7d056d9a5f611eb27f8280425efbf03634690a02f26b957a
 *
 * second, cast wallet to sign the message and we used sliptSignature to split into v,r,s
 * cast wallet sign --no-hash 0x39430e4990aa8a1f7d056d9a5f611eb27f8280425efbf03634690a02f26b957a --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 * 0xcb9c76894253dcc479ded48d675f2d377b47e4a26fb84df1720aedc78475b2243e3d91f574c0189df142aca740d1b17ed500b87f21bd300f1b067192a17b79c81c the signature
 *
 * then run the script to claim the airdrop, pk is from anvil
 * forge script script/Interactions.s.sol:ClaimAirdrop \
 *   --rpc-url http://localhost:8545 \
 *   --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
 *   --broadcast
 * 
 * check balance of the user
 * cast call 0xA1B701E58cCbde8AfE4Cc2aA689513C5030CcED4 "balanceOf(address)" 0x76Cdd5a850a5B721A4f8285405d8a7ab5c3fc7E4 --rpc-url http://localhost:8545
 * 0x0000000000000000000000000000000000000000000000015af1d78b58c40000
 * 
 * convert hash to decimal
 * cast to-dec 0x0000000000000000000000000000000000000000000000015af1d78b58c40000
 * 25000000000000000000
 */
