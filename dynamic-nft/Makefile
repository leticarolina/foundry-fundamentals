deploy-sepolia:
	forge script script/MoodNft.s.sol:DeployMoodNft --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
mint:
	cast send 0x430C13110052A6e203b4a9F57d22Ec4A02678270 "mintNft()" --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK
changeMood: 
	cast send 0x430C13110052A6e203b4a9F57d22Ec4A02678270 "changeMood(uint256)" 0 --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK
checkMood:
	cast call 0x430C13110052A6e203b4a9F57d22Ec4A02678270 "tokenURI(uint256)" 0 --rpc-url $SEPOLIA_RPC_URL