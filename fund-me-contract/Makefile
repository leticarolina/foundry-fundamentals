-include .env

deploy-sepolia:
	forge script script/FundMe.s.sol:FundMeScript --rpc-url $(SEPOLIA_URL) --private-key $(PRIVATE_KEY) --broadcast  --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
