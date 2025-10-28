//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Merkle Airdrop Contract with EIP-712 Signed Claims
 * @notice This contract allows users to claim tokens from an airdrop using Merkle proofs and EIP-712 signatures.
 * @dev Users must provide a valid Merkle proof and a signature to claim their allocated tokens.
 */
contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////////
    //  ERRORS
    //////////////////////////////////////////////////////////////////
    error MerkleAirdrop__hasAlreadyClaimed();
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__TransferFailed();

    //////////////////////////////////////////////////////////////////
    //  STATE VARIABLES
    //////////////////////////////////////////////////////////////////
    address[] claimers;
    bytes32 private immutable i_merkleRoot; // The stored root of the merkle tree
    IERC20 private immutable i_airdropToken; // The ERC-20 token being airdropped
    mapping(address => bool) private s_hasClaimed; // Tracks which addresses have claimed their tokens
    bytes32 public constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)"); // EIP-712 type hash
    //AirdropClaim is the struct we are signing off-chain

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    //////////////////////////////////////////////////////////////////
    //  EVENTS
    //////////////////////////////////////////////////////////////////
    event Claim(address accountReceiver, uint256 amountClaim);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * @notice Allows an eligible address to claim their airdropped tokens.
     * It doesn’t care who calls claim() (the msg.sender) anyone can call it on behalf of accountReceiver.
     * @dev
     *  - Verifies the caller has not claimed before.
     *  - Validates that the provided ECDSA signature was created by `accountReceiver`, the private key of that address signed the message.
     *  - Confirms the provided Merkle proof matches the stored Merkle root.
     *  - Transfers the corresponding token amount to the claimer’s address.
     *  - Emits a {Claim} event on success.
     *
     * @param accountReceiver The address of the user receiving the airdrop (the signed account).
     * @param merkleProof The Merkle proof verifying that the (account, amount) leaf exists within the stored Merkle root.
     * @param v The recovery byte of the ECDSA signature.
     * @param r The first 32-byte value of the ECDSA signature.
     * @param s The second 32-byte value of the ECDSA signature.
     *
     * @custom:throws MerkleAirdrop__hasAlreadyClaimed If this address has already claimed.
     * @custom:throws MerkleAirdrop__InvalidProof If the signature or Merkle proof are invalid.
     * @custom:throws MerkleAirdrop__TransferFailed If token transfer fails.
     */
    function claim(address accountReceiver, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        //if using Single Packed Signature (bytes signature) instead on v,r,s
        //(bytes calldata signature) in params
        //and inside _isValidSignature check using recover
        //address signer = ECDSA.recover(digest, signature);

        uint256 amount = 25 * 1e18;

        //check via mapping if address has claimed already
        if (s_hasClaimed[accountReceiver] == true) {
            revert MerkleAirdrop__hasAlreadyClaimed();
        }

        // Checks that the (v,r,s) signature matches accountReceiver
        if (!_isValidSignature(accountReceiver, getMessageHash(accountReceiver, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidProof();
        }

        // Checks Merkle proof for (accountReceiver, amount)
        //second preimage attack
        // This implementation double-hashes the abi.encoded data.
        // Consistency between off-chain leaf generation and on-chain verification is paramount.
        //leaf is the hashed data the user is claiming
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(accountReceiver, amount))));
        //MerkleProof.verify checks if the leaf is part of the Merkle tree defined by root
        //merkleProof is the array of hashes from the leaf to the root of the tree
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[accountReceiver] = true;

        emit Claim(accountReceiver, amount);
        //This is the airdrop itself. It sends tokens from the contract to someone’s wallet.
        bool sent = i_airdropToken.transfer(accountReceiver, amount);
        if (!sent) {
            revert MerkleAirdrop__TransferFailed();
        }
    }

    /**
     * @notice Computes the EIP-712 message hash for an airdrop claim.
     * @dev
     *  - Produces a deterministic hash representing the leaf params (account, amount) pair under the EIP-712 domain.
     *  - The resulting digest must be signed off-chain by the claimer’s private key.
     *  - Used as the message to verify ECDSA signatures in `_isValidSignature`.
     *
     * @param account The address claiming the airdrop.
     * @param amount The token amount associated with this account in the Merkle tree.
     * @return The EIP-712 digest that must be signed off-chain by `account`.
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim(account, amount))));
    }

    /**
     * @notice Verifies that a provided ECDSA signature was produced/signed by a given account using their pk.
     * @dev
     *  - Attempts recovery using the provided (v, r, s) parameters and compares the recovered address to `account`.
     *  - Also supports Ethereum-signed message format (`eth_sign`) fallback for compatibility.
     *  - Returns true if and only if the recovered signer matches the expected account.
     *  - “Did this address really sign this specific message hash?”
     *
     * @param account The expected signer of the message digest.
     * @param digest The EIP-712 digest (output of `getMessageHash`) that was signed off-chain.
     * @param v The recovery byte of the ECDSA signature.
     * @param r The first 32-byte value of the ECDSA signature.
     * @param s The second 32-byte value of the ECDSA signature.
     *
     * @return isValid Boolean indicating whether the signature is valid for the provided account and digest.
     */
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s); //recovering the signer from the signature
        //tryRecover also uses ecrecover under the hood
        if (actualSigner == account) return true; //compare if the recovered signer is the account expected to sign

        // try again with prefixed (eth_sign) format
        bytes32 ethSigned = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
        (address prefixedSigner,,) = ECDSA.tryRecover(ethSigned, v, r, s);
        return (prefixedSigner == account);
    }

    /*//////////////////////////////////////////////////////////////
                           GETTERS
    //////////////////////////////////////////////////////////////*/
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }
}
