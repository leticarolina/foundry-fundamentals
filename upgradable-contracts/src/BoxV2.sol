//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

//Implementation #2
//Differences from BoxV1:
//added setNumber, so now can mutate number. V1 was read-only, V2 can write.
contract BoxV2 is UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number; //uint256 internal number; stays in the same slot index. This is required.
    string internal name;
    uint256 internal timestamp;

    function setBox(uint256 _number, string memory _name) external {
        number = _number;
        name = _name;
        timestamp = block.timestamp;
    }

    function getBox() external view returns (uint256, string memory, uint256) {
        return (number, name, timestamp);
    }

    function getVersion() external pure returns (string memory) {
        return "v2";
    }

    //When you upgrade to V2, the proxy logic will now use BoxV2’s _authorizeUpgrade.
    //If V2 doesn’t guard it here with onlyOwner, upgrades will be unlocked for anyone. That’s how upgradeable-contract hacks happen.
    //When upgrading to a new implementation, MUST preserve or tighten access control to _authorizeUpgrade.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
