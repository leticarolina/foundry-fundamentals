//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
//gives access to upgradeToAndCall, and the internal _authorizeUpgrade hook. This is what makes the contract "UUPS upgradeable."
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
// Storage is stored in the proxy, since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
// external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
// function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
//same idea as OpenZeppelin’s Ownable, but safe for upgradeable contracts

//Implementation #1 
// deploy implementation > deploy proxy > call initialize() on the proxy (acts like the constructor)
contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal number; //storage lives in the proxy

    constructor() {
        _disableInitializers(); //it says dont let any initializations happens
        //or could just not have this constructor at all
    }
    
    //This acts like “constructor” for the proxy instance.
    //this is in case we do want a constructor, initalize func is the constructor for proxies
    //after deployment contract will immediately call this function
    //tipically initializer funcs has __
    //initializer modifier that lets call initalize only once
    function initialize() public initializer {
        //sets the owner to whoever calls initialize() through the proxy.
        __Ownable_init(msg.sender); //here owner to msg.sender instead of regular set on constructor
        __UUPSUpgradeable_init(); //opt sets up internal UUPS bookkeeping.
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function getVersion() external pure returns (string memory) {
        return "v1";
    }
    
    //This function is REQUIRED by UUPSUpgradeable.
    //Whenever someone calls upgradeToAndCall, OZ will internally call _authorizeUpgrade.
    //By making it onlyOwner: Only the owner can upgrade the proxy to point at a new implementation.
    //That’s your upgrade access control. _authorizeUpgrade is where you decide “who is allowed to upgrade”
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}

/* 
So deployment flow is:
Deploy implementation (BoxV1).
Deploy proxy pointing to that implementation.
Call initialize() on the proxy (not on the implementation!), which sets up owner, etc. 
*/