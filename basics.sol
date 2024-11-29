//foundry comes with 4 components
//forge
//cast
//anvil
//chisal

//========== FORGE
//forge --help = all forge commands
//forge init = Sets up a new minimal, smart contract project using the foundry development framework.
//forge build or forge compile = compile the code aka makes machine readable
//anvil - Create a local testnet node for deploying and testing smart contracts. It can also be used to fork other EVM compatible networks.

//DEPLYING A SMART CONTRACT FROM THE TERMINAL
//forge create - Deploy a smart contract.
//Example full deploy of 'Simple storage
forge create <path>:<contractname> --rpc-url 127.0.0.1:8545 --interactive
//then it will prompt to insert private key
//my first deplyment details on anvil
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Transaction hash: 0x2149ff2c85a2c7fb1e2b9e971d7c20f2dc81fcb5b37e39843f883914be6573d7
//the most explicit way to deply on anvil (but NEVER post private key special real one like that in plain text)
// forge create SimpleStorage --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

//========== CAST

//cast --to-base pasteHex dec = will convert any hex to number 
//cast --help = for the other available commands