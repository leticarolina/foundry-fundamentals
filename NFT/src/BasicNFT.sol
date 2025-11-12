// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol"; //inherits all the ERC-721 standard functions and behaviors.

/// @title NFT Colletion via IPFS
/// @author Leticia Azevedo
/// @notice This contract represents the collection of NFTs, each NFT is a unique token within the contract
/// unique nft is a combination of the contract address + the token ID
contract LeticiaNFT is ERC721 {
    error NFT__AllSupplyHasBeenMinted();
    error NFT__AlreadyMinted();

    uint256 public constant MAX_SUPPLY = 10;
    uint256 private tokenId; //counter to keep track of token IDs
    mapping(uint256 => string) private s_tokenIDToURI; //mapping from token ID to token URI
    mapping(address => bool) private s_hasMinted;
    // The smart contract doesn’t store the image, it only knows the URI that points to the metadata file, and metadata file points to image.
    string private constant URI =
        "ipfs://QmUJeMau6ywH4ff3kPRtE23hVr3Xw8hhW4aLbt4uqAzVNv";

    constructor() ERC721("LeticiaAzevedo", "LA") {
        tokenId = 0;
    }

    /// @notice This is where new NFTs are created
    /// @dev uses the metadata URI that lives off-chain (IPFS)
    /// @dev It stores that URI in the mapping: s_tokenIDToURI[tokenId]
    /// @dev _safeMint() inherited from OZ, checks if the receiver can handle NFTs (important if minting to a smart contract).
    function mintNft() public {
        if (s_hasMinted[msg.sender]) {
            revert NFT__AlreadyMinted();
        }
        if (tokenId >= MAX_SUPPLY) {
            revert NFT__AllSupplyHasBeenMinted();
        }
        s_tokenIDToURI[tokenId] = URI; //It stores that URI in the mapping s_tokenIDToURI[tokenId]
        s_hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tokenId); //mint the NFT to the sender with current token ID
        tokenId++; //increment the token ID counter for next mint
    }

    /// @notice Given the NFT's ID it returns the string URI of that ID
    /// @dev It’s overriding the base ERC-721 tokenURI()
    function tokenURI(
        uint256 idNumber
    ) public view override returns (string memory) {
        return s_tokenIDToURI[idNumber];
    }
}
