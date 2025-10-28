//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
// Storage is stored in the proxy, since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
// external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
// function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

//proxy > deploy implementation > calls iniitalizer functions the 'constrcutor'
contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    constructor() {
        _disableInitializers(); //it says dont let any initializations happens
        //or could just not have this constructor at all
    }

    //this is in case we do want a constructor, initalize func is the constructor for proxies
    //after deployment contract will immediately call this function
    //tipically initializer funcs has __
    //initializer modifier that lets it initalize only once
    function initialize() public initializer {
        __Ownable_init(msg.sender); //sets here owner to msg.sender instead of regular set on constructor
        __UUPSUpgradeable_init();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function getVersion() external pure returns (string memory) {
        return "v1";
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
