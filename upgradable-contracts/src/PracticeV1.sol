// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// gives you upgradeToAndCall() and the _authorizeUpgrade() hook. This is what makes the contract upgradeable at all. Without it the proxy can never point to a new implementation.
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// gives you the initializer modifier. Without it you can't protect your initialize() function from being called multiple times.
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// same as OZ regular Ownable but safe for upgradeable contracts. The regular Ownable sets owner in the constructor which doesn't work with proxies. This version sets owner in __Ownable_init() inside initialize() instead.

/**
 * @title PracticeV1
 * @author Leticia Azevedo (@letiweb3 on X)
 * @notice A practice UUPS upgradeable contract mimicking HumanBond's structure.
 *         Has: external contract address, protocol parameters, mappings, structs, events, setters.
 *         V1 — basic registration flow only.
 */
contract PracticeV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // ----------------------------------------------------------------
    // ERRORS
    // ----------------------------------------------------------------
    error Practice__AlreadyRegistered();
    error Practice__NotRegistered();
    error Practice__InvalidAddress();
    error Practice__CooldownActive();

    // ----------------------------------------------------------------
    // STRUCTS
    // ----------------------------------------------------------------
    struct Profile {
        address user;
        string name;
        uint256 registeredAt;
        bool active;
    }

    // ----------------------------------------------------------------
    // STATE VARS
    // ----------------------------------------------------------------
    // Every state variable takes a slot, constant/immutable is the exception — baked into bytecode, no slot.

    // External contract reference — updatable via setter
    address public rewardToken; // slot 0

    // Protocol parameters — updatable via setters
    uint256 public cooldownPeriod; // slot 1
    uint256 public maxNameLength; // slot 2

    // Mappings — live in proxy storage forever
    mapping(address => Profile) public profiles; // slot 3 (mapping itself takes a slot, but the values are stored in a different location based on the key)
    mapping(address => uint256) public lastActionTimestamp; // slot 4

    // Counters — like activeMarriageCount in HumanBond
    uint256 public totalRegistered; // slot 5
    uint256 public activeUsers; // slot 6

    // Storage gap — reserve 50 slots for future variables
    uint256[43] private __gap; // 50 total - 7 used = 43 left , next var takes slot 7

    // ----------------------------------------------------------------
    // EVENTS
    // ----------------------------------------------------------------
    event UserRegistered(address indexed user, string name, uint256 timestamp);
    event UserDeactivated(address indexed user, uint256 timestamp);
    event RewardTokenUpdated(
        address indexed oldToken,
        address indexed newToken
    );
    event CooldownPeriodUpdated(uint256 oldCooldown, uint256 newCooldown);

    // ----------------------------------------------------------------
    // CONSTRUCTOR — disables initializers on implementation directly
    // ----------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ----------------------------------------------------------------
    // INITIALIZER — replaces constructor, called once through proxy
    // ----------------------------------------------------------------
    function initialize(
        address _rewardToken,
        uint256 _cooldownPeriod,
        uint256 _maxNameLength
    ) public initializer {
        if (_rewardToken == address(0)) revert Practice__InvalidAddress();

        __Ownable_init(msg.sender); // basically sets owner to msg.sender, but through the initializer instead of constructor
        __UUPSUpgradeable_init(); // sets up internal UUPS bookkeeping, not strictly necessary but good practice to call all parent initializers

        rewardToken = _rewardToken;
        cooldownPeriod = _cooldownPeriod;
        maxNameLength = _maxNameLength;
    }

    // ----------------------------------------------------------------
    // CORE FUNCTIONS
    // ----------------------------------------------------------------

    /// @notice Register a profile. One per address.
    function register(string calldata name) external {
        if (profiles[msg.sender].active) revert Practice__AlreadyRegistered();
        if (bytes(name).length == 0 || bytes(name).length > maxNameLength)
            revert Practice__InvalidAddress();
        if (block.timestamp - lastActionTimestamp[msg.sender] < cooldownPeriod)
            revert Practice__CooldownActive();

        profiles[msg.sender] = Profile({
            user: msg.sender,
            name: name,
            registeredAt: block.timestamp,
            active: true
        });

        lastActionTimestamp[msg.sender] = block.timestamp;
        totalRegistered++;
        activeUsers++;

        emit UserRegistered(msg.sender, name, block.timestamp);
    }

    /// @notice Deactivate your own profile.
    function deactivate() external {
        if (!profiles[msg.sender].active) revert Practice__NotRegistered();

        profiles[msg.sender].active = false;
        lastActionTimestamp[msg.sender] = block.timestamp;
        activeUsers--;

        emit UserDeactivated(msg.sender, block.timestamp);
    }

    // ----------------------------------------------------------------
    // SETTERS — owner only, updatable after deployment
    // ----------------------------------------------------------------

    /// @notice Update the reward token address — like setWorldId in HumanBond
    function setRewardToken(address _rewardToken) external onlyOwner {
        if (_rewardToken == address(0)) revert Practice__InvalidAddress();
        emit RewardTokenUpdated(rewardToken, _rewardToken);
        rewardToken = _rewardToken;
    }

    /// @notice Update cooldown period
    function setCooldownPeriod(uint256 _cooldown) external onlyOwner {
        emit CooldownPeriodUpdated(cooldownPeriod, _cooldown);
        cooldownPeriod = _cooldown;
    }

    /// @notice Update max name length
    function setMaxNameLength(uint256 _max) external onlyOwner {
        maxNameLength = _max;
    }

    // ----------------------------------------------------------------
    // GETTERS
    // ----------------------------------------------------------------

    function getProfile(address user) external view returns (Profile memory) {
        return profiles[user];
    }

    function isActive(address user) external view returns (bool) {
        return profiles[user].active;
    }

    function getVersion() external pure virtual returns (string memory) {
        return "v1";
    }

    // ----------------------------------------------------------------
    // UUPS REQUIRED
    // ----------------------------------------------------------------
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
