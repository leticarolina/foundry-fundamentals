//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Test} from "forge-std/Test.sol";
import {LeticiaNFT} from "../src/BasicNFT.sol";
import {DeployNFT} from "../script/DeployNFT.s.sol";

contract LeticiaNFTTest is Test {
    DeployNFT public deployer;
    LeticiaNFT public leticiaNft;
    address public USER = makeAddr("user");

    string private constant URI =
        "ipfs://QmUJeMau6ywH4ff3kPRtE23hVr3Xw8hhW4aLbt4uqAzVNv";

    function setUp() public {
        deployer = new DeployNFT();
        leticiaNft = deployer.run();
    }

    function testNameIsCorrect() public view {
        string memory expectedName = "LeticiaAzevedo";
        string memory actualName = leticiaNft.name();
        assert(
            keccak256(abi.encodePacked(expectedName)) ==
                keccak256(abi.encodePacked(actualName))
        );
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        leticiaNft.mintNft();

        assert(leticiaNft.balanceOf(USER) == 1);
        assert(
            keccak256(abi.encodePacked(URI)) ==
                keccak256(abi.encodePacked(leticiaNft.tokenURI(0)))
        );
    }

    function testCannotMintTwice() public {
        vm.prank(USER);
        leticiaNft.mintNft();

        vm.prank(USER);
        vm.expectRevert(LeticiaNFT.NFT__AlreadyMinted.selector);
        leticiaNft.mintNft();
    }

    function testMaxSupplyLimit() public {
        for (uint256 i = 0; i < 10; i++) {
            address minter = makeAddr(string(abi.encodePacked("user", i)));
            vm.prank(minter);
            leticiaNft.mintNft();
        }

        // All suply minted, next one should fail
        vm.prank(USER);
        vm.expectRevert(LeticiaNFT.NFT__AllSupplyHasBeenMinted.selector);
        leticiaNft.mintNft();
    }
}

//contract address on Sepolia:
//https://sepolia.etherscan.io/address/0x301850dFdFf5AfBD4d7b8032D60908e4AD9eEE49
//corrected version with ID count starting at 0
//https://sepolia.etherscan.io/address/0x79AfAf6b21C00E4F244E7533749C406aea0318Bb