// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//----------------FOUNDRY-------------------
//foundry comes with 4 components
//forge - Compile, Deploy and test smart contracts.
//cast - Interact with smart contracts and the Ethereum network.
//anvil - Create a local testnet node for deploying and testing smart contracts. It can also be used to fork other EVM compatible networks.
//chisal - A tool for formatting and linting Solidity code.

//========== FORGE
//forge --help = all forge commands
//forge init = Sets up a new minimal, smart contract project using the foundry development framework (with src,test,cache)
//forge build/forge compile = compile the code aka makes machine readable
//forge fmt = will auto format the solidity code
//forge test = run tests in the test folder
//forge create - Deploy a smart contract.

//Examples full deploy of 'Simple storage with script

// forge script script/DeploySimpleStorage.s.sol
// deploy with forge script and no rpc-url will use temporary anvil node

//forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key xxxyyyzzz --interactive
//--interactive flag allows you to interact with the script during execution, such as confirming transactions or providing input.
// this will deploy the contract with script and broadcast it to the network.

//============ CAST====================
//trick cast can convert hex to decimal
//cast --to-base pasteHex dec - will convert any hex to number

//cast wallet with pk
//cast c

//cast wallet import nameOfAccountGoesHere --interactive =  import an existing wallet or Ethereum account into your local environment.
//then paste pk, and after create a password, this will be to access the address that refer to the pk (the pk will b encrypted to an address

//========== ANVIL
//deploying with forge/anvil
//anvil - Create a local testnet node for deploying and testing smart contracts. It can also be used to fork other EVM compatible networks.

//forge create <path>:<contractname> --rpc-url --interactive --broadcast(e.g. forge create SimpleStorage --rpc-url http://127.0.0.1:8545 --interactive)
//Additionally the --broadcast flag is for publishing your transaction to the network as a safety precaution and mirrors the --broadcast flag of forge script. If you do not pass the --broadcast flag your transaction is a dry-run.

//forge script script/DeploySimpleStorage.s.sol
//deploting with forge script and no rpc-url will use temporary anvil node

//========== CHISAL

//=============== Scripts =====================
//
