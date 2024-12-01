//foundry comes with 4 components
//forge
//cast
//anvil
//chisal

//========== FORGE
//forge --help = all forge commands
//forge init = Sets up a new minimal, smart contract project using the foundry development framework. with src,test,cache
//forge build or forge compile = compile the code aka makes machine readable
//anvil - Create a local testnet node for deploying and testing smart contracts. It can also be used to fork other EVM compatible networks.
//forge fmt = will auto format the solidity code 


//--------------  DEPLOYING AND INTERACTING WITH A CONTRACT ----------------------------------------
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
// forge create SimpleStorage --rpc-url http://127.0.0.1:8545 --private-y 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80ke

//========== CAST

//cast --to-base pasteHex dec = will convert any hex to number 
//cast --help = for the other available commands
//cast wallet list = to see all the configured wallets


//history -c = clear terminal history 
//rm .bash_history = is used to delete the .bash_history file, which contains a log of the commands you’ve executed in your terminal session, no undo.


//========== NEW METHOD FOR PRIVATE KEY INSTEAD OF .ENV ==================
//Use erc-2335, this is the new way for makindg pk secure

//cast wallet import nameOfAccountGoesHere --interactive =  import an existing wallet or Ethereum account into your local environment. 
//then paste pk, and after create a password, this will be to access the address that refer to the pk (the pk will b encrypted to an address) 
//Once imported, the wallet will be stored in Foundry's local keystore for use with tools like cast and forge.

//account 2 sepholia
`acc2SepholiaWallet` keystore was saved successfully. Address: 0x76cdd5a850a5b721a4f8285405d8a7ab5c3fc7e4

//example on terminal below

/*
This is a multi-line comment.
*/
cast wallet import myAnvilWallet --interactive
Enter private key:
Enter password: `myAnvilWallet` keystore was saved successfully. Address: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266

//example deploying with private key or .env (without broadcast keyword it wont send it will simulate)
//forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --private-key xxxx --broadcast
//if it return "ONCHAIN EXECUTION COMPLETE AND SUCESSFUL"

//examples deploying wiith erc-2335
//ps only forge supports the --account, --sender, and --broadcast options for deploying and interacting with smart contracts using named accounts. cast does not but can use --interactive
forge script /Users/admin/Documents/GitHub/foundry-fundamentals/simple-storage/script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --account myAnvilWallet --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 --broadcast
forge script script/DeploySimpleStorage.s.sol --rpc-url $SEPOLIA_RPC_URL --account acc2SepholiaWallet --sender 0x76cdd5a850a5b721a4f8285405d8a7ab5c3fc7e4 --broadcast

//deployed (example view fromm terminal)
//##### anvil-hardhat
✅  [Success] Hash: 0xdbd2a92a81460031baaf52ea9d6d2786ebb42ab8301d7620c7cae3e4b197d9d6
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Block: 2
Paid: 0.000305357703110304 ETH (347828 gas * 0.877898568 gwei)

✅ Sequence #1 on anvil-hardhat | Total Paid: 0.000305357703110304 ETH (347828 gas * avg 0.877898568 gwei)



//example interacting FROM command line (cast send)
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "addPerson(string, uint256)" "Leticia" 1997 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
//The return from this command

blockHash               0xeb0b71d496617709e6ba63b453dda7aee5ee479175cb95291fc77f60db05384a
blockNumber             2
contractAddress         
cumulativeGasUsed       111606
effectiveGasPrice       878399985
from                    0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
gasUsed                 111606
logs                    []
logsBloom               0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
root                    
status                  1 (success)
transactionHash         0xc3d4f795eb10ad8ed943e8fbbe1e383954167f6f6038874b64ab5d78ccc2c15d
transactionIndex        0
type                    2
blobGasPrice            1
blobGasUsed             
authorizationList       
to                      0x5FbDB2315678afecb367f032d93F642f64180aa3

//checking interaction I just sent (cast call) with the getter function
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getPerson(uint256)(uint256,string)" 0
//it return 
1997
"Leticia"
//with interactive 
cast send 0xd730Ea341f990900cC5f55AC510D02aE608EFdE9 "addPerson(string,uint256)" "Leticia" 1997 --rpc-url $SEPOLIA_RPC_URL --interactive
https://sepolia.etherscan.io/tx/0x07748fe845031cec4d60bca8d61fd44b6309ea59c7c59c09c90389408adf9cc3 


//if it returns in hex need to convert, However, the method of conversion depends on the type of data you're working with
//cast --to-base paste the pastwTheHex dec

//my first contract posted on sepolia https://sepolia.etherscan.io/tx/0x512bf06d8735cd88a07fa53a3a2fb3872be4086e01b6f38f65a65e0bf9124d0b 

// --------------------------- verify a smart contract on ethereum -------------------
//i just did it can check here https://sepolia.etherscan.io/address/0xd730ea341f990900cc5f55ac510d02ae608efde9#code
followed this tutorial but...= https://updraft.cyfrin.io/courses/foundry/foundry-simple-storage/verify-smart-contract-etherscan?lesson_format=video

//