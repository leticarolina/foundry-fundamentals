// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

//User signs UserOp
//Bundler picks it up from alt-mempool → Bundler wraps it into a real tx calling EntryPoint.handleOps()
//EntryPoint calls your smart account.

// The flow for ERC-4337 typically involves an EntryPoint contract calling into this account contract.
// EntryPoint = The EntryPoint contract is the central orchestrator. It first verifies the UserOperation.
//This verification step involves calling a specific function on the user's smart contract wallet (our MinimalAccount.sol).

//contract is IAccount, this tells the compiler that our MinimalAccount contract promises to implement all functions defined in the IAccount interface

contract MinimalAccount is IAccount {
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        // This function will be implemented to validate the user operation.
        // For now, it returns a placeholder value.
        return missingAccountFunds;
    }
}
