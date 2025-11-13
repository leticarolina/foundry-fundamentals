// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Dynamic Mood NFT
/// @author Leticia Azevedo
/// @notice After minting you can change NFT art by caling changeMood(uint256 tokenId)
contract MoodNft is ERC721 {
    error MoodNFT__NotOwnerOfThisTokenId();
    string private s_sadMedatadaUri;
    string private s_happyMedatadaUri;
    uint256 private s_tokenCounter;
    mapping(uint256 => Mood) private s_tokenIdToMood;

    enum Mood {
        HAPPY,
        SAD
    }

    constructor() ERC721("Mood NFT", "MN") {
        s_tokenCounter = 0;
        //Two metadata URIs stored in the contract
        s_sadMedatadaUri = "ipfs://QmTifASR7PDHwbLhyejSLLZxnZ5EaiRjP7E4Nfjcv6d4fN";
        s_happyMedatadaUri = "ipfs://QmetztQcm12FHgL6ah5FJeMqAjyWRG36zTMaELYYYBFj94";
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdToMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    //When someone calls tokenURI(tokenId),  smart contract checks the current mood using enum
    //flips the mood accordingly
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        // string memory imageURI;
        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            return s_happyMedatadaUri;
        } else {
            return s_sadMedatadaUri;
        }
    }

    //calling changeMood(tokenId), flip the enum value
    //Next time you tokenURI() after changeMood(), it now returns the other IPFS link
    //So the NFT’s metadata URI changed → the front-end can show the “sad” or “happy” version accordingly
    function changeMood(uint256 tokenId) public {
        // Only owner or approved address can change mood
        address owner = _ownerOf(tokenId);
        if (!_isAuthorized(owner, msg.sender, tokenId)) {
            revert MoodNFT__NotOwnerOfThisTokenId();
        }

        if (s_tokenIdToMood[tokenId] == Mood.HAPPY) {
            s_tokenIdToMood[tokenId] = Mood.SAD;
        } else {
            s_tokenIdToMood[tokenId] = Mood.HAPPY;
        }
    }

    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }
}

//https://sepolia.etherscan.io/address/0x430C13110052A6e203b4a9F57d22Ec4A02678270
