//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BlackBean} from "../src/BlackBean.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; //from foundry-devops to check if chain working on is zksync or not

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public merkleAirdrop;
    BlackBean public blackBean;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo =
        0x1bb96f63c531e773ee0e7a465cf042becb72dfee0ba16636e73889917df51885;
    bytes32 public immutable ROOT =
        0x943b3c6ac3580cdba39002a0d542b36497d89ab564419fdc318827270ebc2e74;
    uint256 public immutable AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public immutable INITIAL_MINT = 100e18;
    bytes32[] public PROOF = [proofOne, proofTwo];
    address user;
    uint256 userPk;
    address gasPayer;

    function setUp() public {
        if (!isZkSyncChain()) {
            //deploy a script
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, blackBean) = deployer.run();
        } else {
            blackBean = new BlackBean();
            merkleAirdrop = new MerkleAirdrop(ROOT, blackBean);
            blackBean.mint(blackBean.owner(), INITIAL_MINT);
            blackBean.transfer(address(merkleAirdrop), INITIAL_MINT);
        }
        (user, userPk) = makeAddrAndKey("user"); //0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
        gasPayer = makeAddr("gasPayer");
        console.log("User:", user);
        console.log("User private key:", vm.toString(userPk));
        vm.deal(gasPayer, 1 ether);
    }

    function test_claim_works() public {
        console.log("user address:", user);
        uint256 startingBalance = blackBean.balanceOf(user);
        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);
        vm.stopPrank();
        //gaspayer calls the function on behalf of user
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBalance = blackBean.balanceOf(user);

        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
