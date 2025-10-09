// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
This is a multi-line comment.
my very first deployed contract: https://sepolia.etherscan.io/tx/0x4ba2602b64c1c1a086df3c302ce865f34462a6a296d8c6185afb115f4725f4bc 
deployed later on but verified: https://sepolia.etherscan.io/tx/0x512bf06d8735cd88a07fa53a3a2fb3872be4086e01b6f38f65a65e0bf9124d0b
deployed to sepolia but via alchemy rpc-url: https://sepolia.etherscan.io/tx/0x8f43a4d265518451b8a175a486f0e89d7c99bd9075aa263e77369e2494fb6916
*/

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
//forge create - Deploy a smart contract, but it does not execute the constructor.
//forge script - Deploy a smart contract and execute its constructor.
//forge inspect <contract_name> - Inspect the contract's bytecode, ABI, and other details like storage slots.
//forge remappings - List the remappings used in the project.
//forge snapshot - show gas usage and storage changes of a contract.
//forge test --mt <test_name> - Run a specific test function in a test contract.
//forge coverage - Generate a coverage report for the smart contracts in the project.
//forge coverage --report debug - Generate a detailed coverage report with debug information.
//forge coverage --report debug > coverage.txt - Save the coverage report to a file named coverage.txt.
//why debug keyword? It will show the line numbers and source code for each line of the coverage report, making it easier to understand which parts of the code are covered by tests and which are not.
//cat coverage.txt | grep Raffle.sol -A 30 = read the file coverage.txt and search for the word Raffle.sol and show 30 lines after it
//cat coverage.txt | grep Raffle.sol -A 40 > raffle_coverage.txt  = '' then save it to a new file called raffle_coverage.txt
//forge remappings > remappings.txt = save the remappings to a file called remappings.txt
//EXAMPLES FULL FORGE DEPLOYMENT OF 'SIMPLE STORAGE'

//1.
// forge script script/DeploySimpleStorage.s.sol
// deploy with forge script since no rpc-url declared, it will use temporary anvil node

//2.
//forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key xxxyyyzzz --interactive
//--interactive flag allows you to interact with the script during execution, such as confirming transactions or providing input.
// this will deploy the contract with script and broadcast it to the network.

//3.
//forge deploy with cast wallet import
//forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --account anvilWallet --sender 0x70997970c51812dc3a010c7d01b50e0d17dc79c8 --broadcast
// it will prompt to insert the password for the wallet, and then deploy the contract using the specified account.
//PS only forge supports the --account, --sender, and --broadcast options for deploying and interacting with smart contracts using named accounts. cast does not but can use --interactive
// forge can use secure wallets (--account) from ERC-2335 keystore files and prompts for password — perfect for deploys and interactions via scripts.
//cast cannot use those secure wallets — it only accepts raw private keys via --private-key or .env.

//============ CAST====================
//cast storage <contract_address> <slot> for reading the storage of a contract
//cast storage 0x71C95911E9a5D330f4D621842EC243EE1343292e 0 , This command reads the storage slot `0` of the contract at address `0x71C95911E9a5D330f4D621842EC243EE1343292e`
//and returns the value stored
//trick cast can convert hex to decimal
//cast --to-base pasteHex dec - will convert any hex to number
//to decode abi encoded data, use cast abi-decode
//cast abi-decode "tuple(uint256,string)" pasteHex
//cast sig "function()" = get the hex signature of a function

//cast wallet with private key, erc-2335, this is the new way for making pk more secure
//cast wallet import is just for wallet generation/management — not actual usage in transactions.
//cast wallet import nameOfAccountGoesHere --interactive =  import an existing wallet or Ethereum account into your local environment.
//then paste pk, and after create a password, this will be to access the address that refer to the pk (the pk will b encrypted to an address
//Once imported, the wallet will be stored in Foundry's local keystore for use with tools like cast and forge.
//`anvilWallet` keystore was saved successfully. Address: 0x70997970c51812dc3a010c7d01b50e0d17dc79c8

//cast wallet list = gets wallets saved on Foundry's local keystore
//cast wallet export nameOfAccountGoesHere = export the wallet to a file, this will be the encrypted pk

//CAST CAN interact with state in a contract
//cast send <contract_address> "<function_signature>" <arguments> --rpc-url --private-key
//cast send 0x71C95911E9a5D330f4D621842EC243EE1343292e "addPerson(string,uint256)" "Leticia" 7 --rpc-url http://127.0.0.1:8545 --private-key xxxyyyzzz
//This command sends a transaction to the contract at address `0x71C95911E9a5D330f4D621842EC243EE1343292e`
//to call the `addPerson` function with the arguments `"Leticia"` and `7`.

//interacting/calling a function that does not change the state of the contract
//cast call <contract_address> "<function_signature>" <arguments>
//cast call 0x71C95911E9a5D330f4D621842EC243EE1343292e "getPerson(uint256)(uint256,string)" 0
//returns 7 "Leticia"
//This command calls the `getPerson` function of the contract with the argument `0`
//and it returns data correctly bcs I have already explicity said to expects a return value of type `(uint256, string)`.

//cast call 0x71C95911E9a5D330f4D621842EC243EE1343292e "getPerson(uint256)" 0
//return a hexadecimal string, because here we only said the data type it takes, but not the return data types.
//The output will be hashed and returned as a hexadecimal string, which can be decoded to get the actual values.
//to decode the abi data
//cast abi-decode "tuple(uint256,string)" pasteHex/ABI

//========== ANVIL
//deploying with forge/anvil
//anvil - Create a local testnet node for deploying and testing smart contracts. It can also be used to fork other EVM compatible networks.

//forge create <path>/<contractname> --rpc-url --interactive --broadcast
//(e.g. forge create SimpleStorage --rpc-url http://127.0.0.1:8545 --interactive --broadcast)
//Additionally the --broadcast flag is for publishing your transaction to the network as a safety precaution and mirrors the --broadcast flag of forge script.
//If you do not pass the --broadcast flag your transaction is a dry-run. without broadcast keyword it wont send it will simulate sending.

//anvil --fork-url <url> --fork-block-number <block_number> --port <port>
//This command starts an Anvil node that forks from the specified URL at the given block number
//and listens on the specified port. This allows you to test your smart contracts against a specific
//state of the Ethereum network, which is useful for debugging and testing purposes.

//========== CHISAL

//=============== Scripts =====================
// --verify --etherscan-api-key $(ETHERSCAN_API_KEY) this is used to verify the contract on Etherscan after deployment via command line
// this is programmatic verification, it will verify the contract on etherscan after deployment automatically and it will use the etherscan api key from the .env file

//----------------- FOUNDRY PATHWAYS AND REMAPPING
//foundry will not recognize this pathway like remix
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
//we need to use/install the github repository https://github.com/smartcontractkit/chainlink-brownie-contracts
//on the terminal first run
// forge install smartcontractkit/chainlink-brownie-contracts --no-commit
//can run also with latest version
// forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit

//then after installed need to redirect pathways from @chainlink to local repository installed
//means when @chainlink/contracts/ replace with lib/chainlink-brownie-contracts/contracts/src/x
// remappings = [
//   '@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/src/',
// ]

//-------------------------------TESTS-----------------------
//4 types of tests
//What can we do to work with addresses outside of our system?
//1. UNIT
//- Testing an specific part of our code

//2.Integration
// -Testing how our code works with other parts of our code.

//3.Forked
// - Testing our code on a simulated real enviroment.

//4.Staging
// - Testing our code in a real enviroment that is not production

// forge test -m nameOfTheFunction -vvv
//then it will run the test only on the fucntion we have written

//checking which parts of our codes are covered by tests
// forge coverage --fork-url $SEPOLIA_RPC_URL
