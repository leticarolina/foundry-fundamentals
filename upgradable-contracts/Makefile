-include .env

deploy-anvil:
	forge script script/DeployBox.s.sol:DeployBox --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

update-contract-anvil: 
	forge script script/UpgradeBox.s.sol:UpgradeBox --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

deploy-box-sepolia:
	forge script script/DeployBox.s.sol:DeployBox --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

update-contract-sepolia:
	forge script script/UpgradeBox.s.sol:UpgradeBox --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PK --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

# ================================================================
# DEPLOY & UPGRADE
# ================================================================

deploy-v1-sepolia:
	forge script script/DeployPracticeV1.s.sol:DeployPracticeV1 \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1 \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

upgrade-v2-sepolia:
	forge script script/UpgradePracticeV2.s.sol:UpgradePracticeV2 \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1 \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

# ================================================================
# INTERACT — replace PROXY_ADDRESS with your deployed proxy
# ================================================================

# Read current version
get-version:
	cast call $(PROXY_ADDRESS) "getVersion()(string)" \
		--rpc-url $(SEPOLIA_RPC_URL)

# Read owner
get-owner:
	cast call $(PROXY_ADDRESS) "owner()(address)" \
		--rpc-url $(SEPOLIA_RPC_URL)

# Read cooldown period
get-cooldown:
	cast call $(PROXY_ADDRESS) "cooldownPeriod()(uint256)" \
		--rpc-url $(SEPOLIA_RPC_URL)

# Read total registered
get-total-registered:
	cast call $(PROXY_ADDRESS) "totalRegistered()(uint256)" \
		--rpc-url $(SEPOLIA_RPC_URL)

# Read active users
get-active-users:
	cast call $(PROXY_ADDRESS) "activeUsers()(uint256)" \
		--rpc-url $(SEPOLIA_RPC_URL)

# Register a user — NAME is passed as argument
# Usage: make register NAME="leticia"
register:
	cast send $(PROXY_ADDRESS) "register(string)" "$(NAME)" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Get profile of an address
# Usage: make get-profile USER=0x123...
get-profile:
	cast call $(PROXY_ADDRESS) "getProfile(address)((address,string,uint256,bool))" \
		$(USER) \
		--rpc-url $(SEPOLIA_RPC_URL)

# Deactivate your profile
deactivate:
	cast send $(PROXY_ADDRESS) "deactivate()" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Check if address is active
# Usage: make is-active USER=0x123...
is-active:
	cast call $(PROXY_ADDRESS) "isActive(address)(bool)" \
		$(USER) \
		--rpc-url $(SEPOLIA_RPC_URL)

# ================================================================
# V2 ONLY — only works after upgrade
# ================================================================

# Update name
# Usage: make update-name NAME="newname"
update-name:
	cast send $(PROXY_ADDRESS) "updateName(string)" "$(NAME)" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Update bio
# Usage: make update-bio BIO="smart contract dev from brazil"
update-bio:
	cast send $(PROXY_ADDRESS) "updateBio(string)" "$(BIO)" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Get bio
# Usage: make get-bio USER=0x123...
get-bio:
	cast call $(PROXY_ADDRESS) "getBio(address)(string)" \
		$(USER) \
		--rpc-url $(SEPOLIA_RPC_URL)

# ================================================================
# ADMIN
# ================================================================

# Update cooldown period
# Usage: make set-cooldown COOLDOWN=86400
set-cooldown:
	cast send $(PROXY_ADDRESS) "setCooldownPeriod(uint256)" $(COOLDOWN) \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Pause contract (V2 only)
pause:
	cast send $(PROXY_ADDRESS) "pause()" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1

# Unpause contract (V2 only)
unpause:
	cast send $(PROXY_ADDRESS) "unpause()" \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1
set-max-name-length:
	cast send $(PROXY_ADDRESS) "setMaxNameLength(uint256)" 12 \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account acc1
