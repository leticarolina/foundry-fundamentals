deploy-anvil:
	forge script script/DeployBox.s.sol:DeployBox --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

update-contract-anvil: 
	forge script script/UpgradeBox.s.sol:UpgradeBox --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-sepolia:
	forge script script/DeployBox.s.sol:DeployBox --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

update-contract-sepolia:
	forge script script/UpgradeBox.s.sol:UpgradeBox --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY