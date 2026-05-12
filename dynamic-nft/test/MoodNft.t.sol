// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {DeployMoodNft} from "../script/MoodNft.s.sol";

contract CounterTest is Test {
    MoodNft moodNft;
    DeployMoodNft deployer;
    string public SAD_URI_METADATA =
        "ipfs://QmTifASR7PDHwbLhyejSLLZxnZ5EaiRjP7E4Nfjcv6d4fN";
    string public HAPPY_URI_METADATA =
        "ipfs://QmZQCawsWtrnMuxcQCukvhKFe64pewjuopQghfbGvzHqJX";

    function setUp() public {
        deployer = new DeployMoodNft();
        (moodNft) = deployer.run();
    }

    function testViewTokenUri() public {
        vm.prank(msg.sender);
        moodNft.mintNft();
        string memory actualUri = moodNft.tokenURI(0);
        assertEq(actualUri, HAPPY_URI_METADATA);
    }

    function testMintIncrementsTokenCounter() public {
        uint256 beforeMint = moodNft.getTokenCounter();
        vm.prank(msg.sender);
        moodNft.mintNft();
        uint256 afterMint = moodNft.getTokenCounter();
        assertEq(afterMint, beforeMint + 1);
    }

    function testChangeMoodFlipsToSad() public {
        vm.startPrank(msg.sender);
        moodNft.mintNft();
        uint256 tokenId = 0;
        moodNft.changeMood(tokenId); // to sad
        vm.stopPrank();
        assertEq(moodNft.tokenURI(tokenId), SAD_URI_METADATA);
    }

    function testOnlyOwnerCanChangeMood() public {
        vm.prank(msg.sender);
        moodNft.mintNft();

        vm.prank(address(0xBEEF)); // simulate another address
        vm.expectRevert(); // expecting a revert
        moodNft.changeMood(0);
    }

    function testTokenURIChangesAfterFlip() public {
        vm.startPrank(msg.sender);
        moodNft.mintNft();
        string memory beforeUri = moodNft.tokenURI(0);
        moodNft.changeMood(0);
        vm.stopPrank();
        string memory afterUri = moodNft.tokenURI(0);

        assertFalse(keccak256(bytes(beforeUri)) == keccak256(bytes(afterUri)));
    }
}
