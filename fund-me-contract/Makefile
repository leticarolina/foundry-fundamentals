-include .env # Load environment variables from env file

deploy-sepolia:
	forge script script/FundMe.s.sol:FundMeScript --rpc-url $(SEPOLIA_URL) --private-key $(SEPOLIA_PK) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# $$SEPOLIA_RPC_URL	Double $ is used to escape Makefiles, equivalent to $SEPOLIA_RPC_URL in bash.

deploy-sepolia:; forge script # same line command 

test:
	forge test -vvv

