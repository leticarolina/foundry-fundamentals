// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWorldID} from "./interfaces/IWorldID.sol";
import {VowNFT} from "./tokens/VowNFT.sol";
import {TimeToken} from "./tokens/TimeToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title MarriageCore (UUPS Upgradeable)
/// @notice Minimal, judge-friendly flow:
///         - Two World ID proofs (one per partner) → Create a canonical pair, mint SBTs.
///         - Optional: both co-sign an hourly session → TIME minted to each.
/// @dev Storage layout is upgrade-safe; add new vars only at the bottom and keep __gap updated.
contract MarriageCore is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    using ECDSA for bytes32;

    // -------------------------
    // World ID config
    // -------------------------
    IWorldID public worldId;
    uint256 public worldGroupId; // e.g., World ID "Semaphore" group
    uint256 public externalNullifier; // app-specific nullifier

    // Prevent proof reuse (per-person)
    mapping(uint256 => bool) public nullifierUsed;

    // -------------------------
    // Protocol assets
    // -------------------------
    VowNFT public vowNFT;
    TimeToken public timeToken;

    // Mint parameters
    uint256 public timePerHourPerPartner; // e.g., 1e18 (1 TIME with 18 decimals)
    bool public mintTimeOnSession;

    // -------------------------
    // Pair state
    // -------------------------
    enum Status {
        NONE,
        ACTIVE,
        DISSOLVED
    }

    struct Pair {
        address a;
        address b;
        uint64 since;
        Status status;
        uint256 tokenIdA;
        uint256 tokenIdB;
    }

    /// @dev Canonical pair key is keccak(sorted(a,b))
    mapping(bytes32 => Pair) public pairs;
    mapping(address => address) public partnerOf;

    // EIP712 typed-data for session co-sign
    // keccak256("SessionConsent(address partner,uint64 startedAt,uint32 hoursWorked,uint256 nonce,uint256 deadline)")
    bytes32 public constant SESSION_TYPEHASH =
        keccak256(
            "SessionConsent(address partner,uint64 startedAt,uint32 hoursWorked,uint256 nonce,uint256 deadline)"
        );

    // Nonces per address to avoid replay
    mapping(address => uint256) public nonces;

    // -------------------------
    // Events
    // -------------------------
    event VowCreated(
        bytes32 indexed pairId,
        address indexed a,
        address indexed b,
        uint64 since,
        uint256 tokenIdA,
        uint256 tokenIdB
    );
    event VowDissolved(
        bytes32 indexed pairId,
        address indexed a,
        address indexed b,
        uint64 at
    );
    event SessionLogged(
        bytes32 indexed pairId,
        address indexed a,
        address indexed b,
        uint64 startedAt,
        uint32 hoursWorked,
        uint256 timeMintedEach
    );

    // -------------------------
    // Errors
    // -------------------------
    error InvalidPartner();
    error AlreadyPaired();
    error NotActive();
    error NotPartner();
    error InvalidProof();
    error DeadlineExpired();
    error BadSignature();
    error ZeroAddress();
    error HoursZero();
    error AlreadyUsedNullifier();
    error SameAddress();

    // -------------------------
    // Initializer (UUPS)
    // -------------------------
    /// @param worldId_           Address of deployed World ID contract
    /// @param worldGroupId_      Semaphore group id
    /// @param externalNullifier_ App-specific external nullifier
    /// @param vowNFT_            Address of deployed VowNFT
    /// @param timeToken_         Address of deployed TimeToken
    /// @param timePerHour_       Amount of TIME to mint per hour per partner (e.g., 1e18)
    /// @param eip712Name_        Domain name for EIP-712
    /// @param eip712Version_     Domain version for EIP-712
    function initialize(
        address worldId_,
        uint256 worldGroupId_,
        uint256 externalNullifier_,
        address vowNFT_,
        address timeToken_,
        uint256 timePerHour_,
        string memory eip712Name_,
        string memory eip712Version_
    ) external initializer {
        if (
            worldId_ == address(0) ||
            vowNFT_ == address(0) ||
            timeToken_ == address(0)
        ) revert ZeroAddress();

        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __EIP712_init(eip712Name_, eip712Version_);

        worldId = IWorldID(worldId_);
        worldGroupId = worldGroupId_;
        externalNullifier = externalNullifier_;
        vowNFT = VowNFT(vowNFT_);
        timeToken = TimeToken(timeToken_);

        timePerHourPerPartner = timePerHour_; // default: 1e18
        mintTimeOnSession = true; // can be toggled by owner
    }

    /// @dev UUPS auth — owner-only upgrades
    function _authorizeUpgrade(address newImpl) internal override onlyOwner {}

    // -------------------------
    // Admin controls
    // -------------------------
    function setMintTimeOnSession(bool enabled) external onlyOwner {
        mintTimeOnSession = enabled;
    }

    function setTimePerHourPerPartner(uint256 amount) external onlyOwner {
        timePerHourPerPartner = amount;
    }

    // -------------------------
    // Vow creation (both World ID proofs in one tx)
    // -------------------------
    struct WorldIDProof {
        uint256 root;
        uint256 nullifierHash;
        uint256[8] proof;
    }

    /// @notice Create a vow between `a` and `b` after verifying both World ID proofs.
    /// @dev Either partner (or a relayer) can submit, but both proofs are required.
    /// @param a First partner wallet
    /// @param b Second partner wallet
    /// @param signal Arbitrary signal committed in the proof (should bind a & b)
    /// @param proofA World ID proof for partner a
    /// @param proofB World ID proof for partner b
    function createVow(
        address a,
        address b,
        bytes32 signal,
        WorldIDProof calldata proofA,
        WorldIDProof calldata proofB,
        string calldata tokenURIa,
        string calldata tokenURIb
    ) external nonReentrant {
        if (a == address(0) || b == address(0)) revert ZeroAddress();
        if (a == b) revert SameAddress();
        if (partnerOf[a] != address(0) || partnerOf[b] != address(0))
            revert AlreadyPaired();

        bytes32 pairId = _pairKey(a, b);
        if (pairs[pairId].status != Status.NONE) revert AlreadyPaired();

        // Verify both World ID proofs; revert on invalid.
        _verifyWorldID(signal, proofA);
        _verifyWorldID(signal, proofB);

        // Mark nullifiers used so they can't be replayed.
        if (
            nullifierUsed[proofA.nullifierHash] ||
            nullifierUsed[proofB.nullifierHash]
        ) revert AlreadyUsedNullifier();
        nullifierUsed[proofA.nullifierHash] = true;
        nullifierUsed[proofB.nullifierHash] = true;

        // Persist pair
        (address a0, address b0) = _sort(a, b);
        pairs[pairId] = Pair({
            a: a0,
            b: b0,
            since: uint64(block.timestamp),
            status: Status.ACTIVE,
            tokenIdA: 0,
            tokenIdB: 0
        });
        partnerOf[a0] = b0;
        partnerOf[b0] = a0;

        // Mint soulbound vow badges to both
        uint256 tokenIdA = vowNFT.mint(a0, tokenURIa);
        uint256 tokenIdB = vowNFT.mint(b0, tokenURIb);

        // Track SBT ids
        pairs[pairId].tokenIdA = tokenIdA;
        pairs[pairId].tokenIdB = tokenIdB;

        emit VowCreated(
            pairId,
            a0,
            b0,
            uint64(block.timestamp),
            tokenIdA,
            tokenIdB
        );
    }

    /// @notice Dissolve an active vow — can be done by either partner (or owner/admin).
    ///         For hackathon simplicity, unilateral dissolve is allowed.
    function dissolveVow() external nonReentrant {
        address p = partnerOf[msg.sender];
        if (p == address(0)) revert NotPartner();

        bytes32 pairId = _pairKey(msg.sender, p);
        Pair storage pr = pairs[pairId];
        if (pr.status != Status.ACTIVE) revert NotActive();

        // Clear partner mappings
        partnerOf[pr.a] = address(0);
        partnerOf[pr.b] = address(0);
        pr.status = Status.DISSOLVED;

        // Burn SBTs
        if (pr.tokenIdA != 0) vowNFT.burn(pr.tokenIdA);
        if (pr.tokenIdB != 0) vowNFT.burn(pr.tokenIdB);

        emit VowDissolved(pairId, pr.a, pr.b, uint64(block.timestamp));
    }

    // -------------------------
    // Session logging (both signatures, no oracle)
    // -------------------------
    /// @notice Both partners co-sign an hourly “session” and (optionally) mint TIME to each partner.
    /// @param partner      The counterparty (must be your current partner)
    /// @param startedAt    UTC start time (seconds)
    /// @param hoursWorked  Number of hours (integer for simplicity)
    /// @param deadline     Sig validity deadline (unix)
    /// @param sigA         Signature by msg.sender
    /// @param sigB         Signature by `partner`
    function logSession(
        address partner,
        uint64 startedAt,
        uint32 hoursWorked,
        uint256 deadline,
        bytes calldata sigA,
        bytes calldata sigB
    ) external nonReentrant {
        if (partner == address(0)) revert ZeroAddress();
        if (hoursWorked == 0) revert HoursZero();
        if (block.timestamp > deadline) revert DeadlineExpired();
        if (partnerOf[msg.sender] != partner) revert InvalidPartner();

        bytes32 pairId = _pairKey(msg.sender, partner);
        Pair memory pr = pairs[pairId];
        if (pr.status != Status.ACTIVE) revert NotActive();

        // Build EIP-712 digest for both addresses (symmetric content)
        uint256 nonceA = nonces[msg.sender]++;
        uint256 nonceB = nonces[partner]++;

        bytes32 structHashA = keccak256(
            abi.encode(
                SESSION_TYPEHASH,
                partner,
                startedAt,
                hoursWorked,
                nonceA,
                deadline
            )
        );
        bytes32 digestA = _hashTypedDataV4(structHashA);

        bytes32 structHashB = keccak256(
            abi.encode(
                SESSION_TYPEHASH,
                msg.sender,
                startedAt,
                hoursWorked,
                nonceB,
                deadline
            )
        );
        bytes32 digestB = _hashTypedDataV4(structHashB);

        // Recover
        address recA = ECDSA.recover(digestA, sigA);
        address recB = ECDSA.recover(digestB, sigB);
        if (recA != msg.sender || recB != partner) revert BadSignature();

        // Mint TIME (optional) — to both partners, same amount.
        uint256 timeMintEach = timePerHourPerPartner * uint256(hoursWorked);
        if (mintTimeOnSession && timeMintEach > 0) {
            timeToken.mint(pr.a, timeMintEach);
            timeToken.mint(pr.b, timeMintEach);
        }

        emit SessionLogged(
            pairId,
            pr.a,
            pr.b,
            startedAt,
            hoursWorked,
            timeMintEach
        );
    }

    // -------------------------
    // Internals
    // -------------------------
    function _verifyWorldID(
        bytes32 signal,
        WorldIDProof calldata p
    ) internal view {
        // Convert signal to field element
        uint256 signalHash = uint256(keccak256(abi.encodePacked(signal)));
        // Will revert if invalid/used according to WorldID contract logic
        worldId.verifyProof(
            p.root,
            worldGroupId,
            signalHash,
            p.nullifierHash,
            externalNullifier,
            p.proof
        );
    }

    function _sort(
        address a,
        address b
    ) internal pure returns (address, address) {
        return (a < b) ? (a, b) : (b, a);
    }

    function _pairKey(address a, address b) internal pure returns (bytes32) {
        (address x, address y) = a < b ? (a, b) : (b, a);
        return keccak256(abi.encodePacked(x, y));
    }

    function verifyAndSignMarriage(
        address partner,
        bytes calldata proofA,
        bytes calldata proofB
    ) {}

    // -------------------------
    // Storage gap (for upgrades)
    // -------------------------
    uint256[40] private __gap;
}
