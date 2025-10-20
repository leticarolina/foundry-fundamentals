//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__hasAlreadyClaimed();
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__TransferFailed();
    address[] claimers;
    bytes32 private immutable i_merkleRoot; // The stored root of the merkle tree
    IERC20 private immutable i_airdropToken;
    mapping(address => bool) private s_hasClaimed;
    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address accountCaller, uint256 amountClaim);

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address accountCaller,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        //check via mapping if address has claimed already
        if (s_hasClaimed[accountCaller] == true) {
            revert MerkleAirdrop__hasAlreadyClaimed();
        }
        // check signature validity
        if (
            !_isValidSignature(
                accountCaller,
                getMessageHash(accountCaller, amount),
                v,
                r,
                s
            )
        ) {
            revert MerkleAirdrop__InvalidProof();
        }
        //second preimage attack
        // This implementation double-hashes the abi.encoded data.
        // Consistency between off-chain leaf generation and on-chain verification is paramount.
        //leaf is the hashed data the use is claiming
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(accountCaller, amount)))
        );
        //MerkleProof.verify checks if the leaf is part of the Merkle tree defined by root
        //merkleProof is the array of hashes from the leaf to the root of the tree
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[accountCaller] = true;

        emit Claim(accountCaller, amount);
        bool sent = i_airdropToken.transfer(accountCaller, amount);
        if (!sent) {
            revert MerkleAirdrop__TransferFailed();
        }
    }

    //some list of address
    //allow someone on the list to claim tokens
    // function _isValidSignature
    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(MESSAGE_TYPEHASH, AirdropClaim(account, amount))
                )
            );
    }

    //the function returns a hash that uniquely represents that claim (address + amount) under the EIP-712 domain.
    //It’s the same digest the user must sign off-chain.

    //verify that the claim was signed by the claimer’s private key
    //tries two different ways of checking that the provided (v, r, s) signature really comes from the account address
    function _isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s); //recovering the signer from the signature
        //tryRecover uses ecrecover under the hood
        //return (actualSigner == account); //compare if the recovered signer is the account expected to sign

        if (actualSigner == account) return true;

        // try again with prefixed (eth_sign) format
        bytes32 ethSigned = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        (address prefixedSigner, , ) = ECDSA.tryRecover(ethSigned, v, r, s);
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
