// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title PracticeV2
 * @author Leticia Azevedo (@letiweb3 on X)
 * @notice Upgrade of PracticeV1.
 *
 * What changed from V1:
 * - Added `bio` field to Profile struct — NOTE: you cannot change existing structs safely.
 *   Instead a separate mapping is added for bio (safe pattern).
 * - Added `totalDeactivations` counter
 * - Added `updateName()` function — V1 had no way to change your name after registering
 * - Added `pause` / `unpause` — new admin feature
 *
 * What did NOT change:
 * - Variable order for existing vars — same slots as V1
 * - initialize() — NOT called again, proxy already has state from V1
 * - _authorizeUpgrade() — still onlyOwner
 * - __gap reduced by 2 (added 2 new variables: totalDeactivations, paused)
 */
contract PracticeV2 is UUPSUpgradeable, OwnableUpgradeable {
    // ----------------------------------------------------------------
    // ERRORS — keep all V1 errors, add new ones
    // ----------------------------------------------------------------
    error Practice__AlreadyRegistered();
    error Practice__NotRegistered();
    error Practice__InvalidAddress();
    error Practice__CooldownActive();
    error Practice__Paused();
    error Practice__NotPaused();

    // ----------------------------------------------------------------
    // STRUCTS — same as V1, do not reorder or remove fields
    // ----------------------------------------------------------------
    struct Profile {
        address user;
        string name;
        uint256 registeredAt;
        bool active;
    }

    // ----------------------------------------------------------------
    // STATE VARS — CRITICAL: same order as V1 for existing vars
    // ----------------------------------------------------------------

    // --- V1 variables in exact same order ---
    address public rewardToken; // slot 0 (after OZ internals)
    uint256 public cooldownPeriod; // slot 1
    uint256 public maxNameLength; // slot 2
    mapping(address => Profile) public profiles; // slot 3
    mapping(address => uint256) public lastActionTimestamp; // slot 4
    uint256 public totalRegistered; // slot 5
    uint256 public activeUsers; // slot 6

    // --- NEW V2 variables — added after all V1 vars ---
    uint256 public totalDeactivations; // slot 7 — new in V2
    bool public paused; // slot 8 — new in V2
    mapping(address => string) public bios; // new mapping — slot 9

    // Gap shrinks by 3 (added totalDeactivations + paused + bios)
    uint256[40] private __gap;

    // ----------------------------------------------------------------
    // EVENTS — keep V1 events, add new ones
    // ----------------------------------------------------------------
    event UserRegistered(address indexed user, string name, uint256 timestamp);
    event UserDeactivated(address indexed user, uint256 timestamp);
    event RewardTokenUpdated(
        address indexed oldToken,
        address indexed newToken
    );
    event CooldownPeriodUpdated(uint256 oldCooldown, uint256 newCooldown);
    event NameUpdated(
        address indexed user,
        string oldName,
        string newName,
        uint256 timestamp
    );
    event BioUpdated(address indexed user, uint256 timestamp);
    event Paused(uint256 timestamp);
    event Unpaused(uint256 timestamp);

    // ----------------------------------------------------------------
    // CONSTRUCTOR — same pattern, always disable initializers
    // ----------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ----------------------------------------------------------------
    // NO initialize() HERE
    // Proxy already has state from V1's initialize().
    // Owner, rewardToken, cooldownPeriod etc are all already set.
    // ----------------------------------------------------------------

    // ----------------------------------------------------------------
    // MODIFIERS
    // ----------------------------------------------------------------
    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() internal view {
        if (paused) revert Practice__Paused();
    }

    // ----------------------------------------------------------------
    // CORE FUNCTIONS — V1 functions stay, new ones added
    // ----------------------------------------------------------------

    /// @notice Same as V1 but respects pause
    function register(string calldata name) external whenNotPaused {
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

    /// @notice Same as V1
    function deactivate() external {
        if (!profiles[msg.sender].active) revert Practice__NotRegistered();

        profiles[msg.sender].active = false;
        lastActionTimestamp[msg.sender] = block.timestamp;
        activeUsers--;
        totalDeactivations++; // new in V2

        emit UserDeactivated(msg.sender, block.timestamp);
    }

    /// @notice NEW in V2 — update your name after registration
    function updateName(string calldata newName) external {
        if (!profiles[msg.sender].active) revert Practice__NotRegistered();
        if (bytes(newName).length == 0 || bytes(newName).length > maxNameLength)
            revert Practice__InvalidAddress();

        string memory oldName = profiles[msg.sender].name;
        profiles[msg.sender].name = newName;

        emit NameUpdated(msg.sender, oldName, newName, block.timestamp);
    }

    /// @notice NEW in V2 — set your bio
    function updateBio(string calldata bio) external {
        if (!profiles[msg.sender].active) revert Practice__NotRegistered();
        bios[msg.sender] = bio;
        emit BioUpdated(msg.sender, block.timestamp);
    }

    // ----------------------------------------------------------------
    // SETTERS — same as V1 plus new ones
    // ----------------------------------------------------------------

    function setRewardToken(address _rewardToken) external onlyOwner {
        if (_rewardToken == address(0)) revert Practice__InvalidAddress();
        emit RewardTokenUpdated(rewardToken, _rewardToken);
        rewardToken = _rewardToken;
    }

    function setCooldownPeriod(uint256 _cooldown) external onlyOwner {
        emit CooldownPeriodUpdated(cooldownPeriod, _cooldown);
        cooldownPeriod = _cooldown;
    }

    function setMaxNameLength(uint256 _max) external onlyOwner {
        maxNameLength = _max;
    }

    /// @notice NEW in V2 — pause/unpause
    function pause() external onlyOwner {
        if (paused) revert Practice__Paused();
        paused = true;
        emit Paused(block.timestamp);
    }

    function unpause() external onlyOwner {
        if (!paused) revert Practice__NotPaused();
        paused = false;
        emit Unpaused(block.timestamp);
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

    function getBio(address user) external view returns (string memory) {
        return bios[user];
    }

    function getVersion() external pure virtual returns (string memory) {
        return "v2";
    }

    // ----------------------------------------------------------------
    // UUPS REQUIRED
    // ----------------------------------------------------------------
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
