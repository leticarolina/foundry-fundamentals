// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//ps: there’s no upgrade logic or admin separation in this example. it’s just educational.

//call = “Go run your code at your place.”
//delegatecall = “Lend me your code — I’ll run it at my place.”
//delegateCall is like saying: I really like your function, I’m going to borrow it and run it in my own contract.

//acts like an implementation (the one with logic)
// note for example: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint256 public numB; //index [0]
    address public senderB; //index [1]
    uint256 public valueB;

    function setVars(uint256 _num) public payable {
        numB = _num; //storageSlot[0] = _num; function cares about updating the slot, not variable name
        senderB = msg.sender;
        valueB = msg.value;
    }
}

//acts like a proxy (the one that holds storage and calls the implementation by delegateCall)
contract A {
    uint256 public numA;
    address public senderA;
    uint256 public valueA;

    event DelegateResponse(bool success, bytes data);
    event CallResponse(bool success, bytes data);

    // Function using delegatecall
    function setVarsDelegateCall(
        address _contract,
        uint256 _num
    ) public payable {
        // A's storage is set; B's storage is not modified.
        //delegatecall here:  Hey _contract, I like your setVars function, lend me to use and I’ll write the result in my own storage (A)
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        emit DelegateResponse(success, data);
    }

    // Function using call
    function setVarsCall(address _contract, uint256 _num) public payable {
        // B's storage is set; A's storage is not modified.
        (bool success, bytes memory data) = _contract.call{value: msg.value}(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        emit CallResponse(success, data);
    }
}
