// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title PermitExample
 * @dev Shows how a dApp can use signatures (EIP-2612) instead of separate approve() transactions.
 */
contract PermitExample {
    IERC20 public immutable token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
//         The signing happens off-chain, not inside your contract.
// The permit() function is just verifying the signature on-chain.
        // Use the user's signature to give this contract allowance
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Transfer tokens using the freshly granted allowance
        token.transferFrom(msg.sender, address(this), amount);
    }
}
