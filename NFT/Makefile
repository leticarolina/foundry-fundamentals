deploy-anvil:
	forge script script/DeployNFT.s.sol:DeployNFT --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-sepolia:
	forge script script/DeployNFT.s.sol:DeployNFT --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
mint:
	cast send 0x79AfAf6b21C00E4F244E7533749C406aea0318Bb "mintNft()" --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK