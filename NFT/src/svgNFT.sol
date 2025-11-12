// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract OnChainSVGNFT is ERC721 {
    uint256 private tokenIdCounter;

    constructor() ERC721("OnChainSVG", "OSVG") {}

    function mint() external {
        _safeMint(msg.sender, tokenIdCounter);
        tokenIdCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300">',
            '<rect width="100%" height="100%" fill="black"/>',
            '<text x="50" y="150" fill="gold" font-size="40">',
            "Leti #",
            Strings.toString(tokenId),
            "</text></svg>"
        );

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"Leti #',
                    Strings.toString(tokenId),
                    '","description":"Fully on-chain SVG NFT",',
                    '"image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(svg)),
                    '"}'
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }
}
