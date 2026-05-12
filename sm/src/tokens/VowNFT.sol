// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title VowNFT (Soulbound)
/// @notice Soulbound “vow” badge for each partner. Minted/burned only by MarriageCore.
contract VowNFT is ERC721, Ownable {
    error NotCore();
    error Soulbound();

    address public core;
    uint256 private _nextId = 1;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

    function setCore(address core_) external onlyOwner {
        core = core_;
    }

    /// @notice Mint a soulbound NFT to `to` and set a tokenURI (optional; empty ok)
    function mint(
        address to,
        string calldata tokenURI_
    ) external returns (uint256 tokenId) {
        if (msg.sender != core) revert NotCore();
        tokenId = _nextId++;
        _safeMint(to, tokenId);
        if (bytes(tokenURI_).length > 0) _tokenURIs[tokenId] = tokenURI_;
    }

    /// @notice Burn a soulbound NFT (e.g., on dissolution)
    function burn(uint256 tokenId) external {
        if (msg.sender != core) revert NotCore();
        _burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) delete _tokenURIs[tokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }

    /// @dev Prevent transfers except mint (from 0) and burn (to 0)
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) revert Soulbound();
        return super._update(to, tokenId, auth);
    }
}
