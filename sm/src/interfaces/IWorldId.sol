// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal World ID interface (IDKit/contract pattern)
/// The canonical interface exposes verifyProof with these params.
interface IWorldID {
    /// @dev MUST revert if the proof is invalid or already used.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external view;
}
