-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEFAULT_ANVIL_KEY_2 := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_ADDRESS_2 := 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
DEFAULT_ZKSYNC_ADDRESS := 0x36615Cf349d7F6344891B1e7CA7C72883F5dc049
DEFAULT_ZKSYNC_LOCAL_KEY := 0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110
SEPOLIA_RPC_URL := $(SEPOLIA_URL)
PRIVATE_KEY := $(SEPOLIA_PK)	
ETHERSCAN_API_KEY := $(ETHERSCAN_KEY)

AIRDROP_ADDRESS := 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
TOKEN_ADDRESS := 0x5FbDB2315678afecb367f032d93F642f64180aa3

# zkSync constants

ROOT := 0x474d994c58e37b12085fdb7bc6bbcd046cf1907b90de3b7fb083cf3636c8ebfb
PROOF_1 := 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad
PROOF_2 := 0x46f4c7c1c21e8a90c03949beda51d2d02d1ec75b55dd97a999d3edbafa5a1e2f
AIRDROP_AMOUNT := 25000000000000000000

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

format :; forge fmt

zk-anvil :; npx zksync-cli dev start

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy:
	@forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop $(NETWORK_ARGS)

deploy-sepolia: 
	forge script script/DeployMerkleAirdrop.s.sol:DeployMerkleAirdrop --rpc-url https://eth-sepolia.g.alchemy.com/v2/hr0u6gssX4yzR3YaMJd5n29e7Cwk79LT --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY
# As of writing, the Alchemy zkSync RPC URL is not working correctly 
deploy-zk:
	forge create src/MerkleAirdrop.sol:MerkleAirdrop --rpc-url http://127.0.0.1:8011 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --constructor-args ${ROOT} $(shell forge create src/BagelToken.sol:BagelToken --rpc-url http://127.0.0.1:8011 --private-key ${DEFAULT_ZKSYNC_LOCAL_KEY} --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --legacy --zksync

deploy-zk-sepolia:
	forge create src/MerkleAirdrop.sol:MerkleAirdrop --rpc-url ${ZKSYNC_SEPOLIA_RPC_URL} --constructor-args ${ROOT} $(shell forge create src/BagelToken.sol:BagelToken --rpc-url ${ZKSYNC_SEPOLIA_RPC_URL} --account default --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --account default --legacy --zksync

# Generate Merkle Tree input file
generate :; forge script script/GenerateInput.s.sol:GenerateInput

# Make Merkle Root and Proofs
merkle :; forge script script/MakeMerkle.s.sol:MakeMerkle

# Generate input and output files 

zktest :; foundryup-zksync && forge test --zksync && foundryup

