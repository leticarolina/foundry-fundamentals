# 🔄 Upgradable Smart Contract Example (UUPS + ERC1967 Proxy)

This project demonstrates how to **deploy, upgrade, and interact with an upgradable smart contract** using the **UUPS pattern** with **OpenZeppelin Upgradeable libraries** and **Foundry**.

It uses a `BoxV1` contract that stores a single number, and an upgraded `BoxV2` contract that adds extra variables and functionality — showing how the proxy keeps its storage between upgrades.

## Deployed Contracts (Sepolia)

- **Proxy:**  
  [0x096De44916a641f67f168475EA706A8d3053E36c](https://sepolia.etherscan.io/address/0x096De44916a641f67f168475EA706A8d3053E36c)

- **BoxV1 (View Code):**  
  [0x80D719b1cC722444a8B86108a41CDD1e8CBe152A](https://sepolia.etherscan.io/address/0x80D719b1cC722444a8B86108a41CDD1e8CBe152A#code)

- **BoxV2 Updagarded (View Code):**  
  [0xe7EB93867bd798454c1d1274d5b1F638e6c8A35B](https://sepolia.etherscan.io/address/0xe7EB93867bd798454c1d1274d5b1F638e6c8A35B#code)

---

## 🧱 Project Structure

- src/
BoxV1.sol # First implementation (UUPS)
BoxV2.sol # Second implementation with new variables
- script/
DeployBox.s.sol # Deploys implementation + proxy + initializes
UpgradeBox.s.sol # Upgrades proxy to new implementation

---

## ⚙️ How It Works

**BoxV1** - Holds one variable `number` with getter/setter functions. |
**BoxV2** - Inherits `BoxV1` and adds new variables (`name`, `bool active`, `timestamp`) and a new `setBox()` function.
**Proxy (ERC1967)** - Stores the actual data and delegates all calls to the implementation logic.
**UUPS pattern** - Lets the implementation contract handle its own upgrades via `_authorizeUpgrade`. 

The proxy **never changes address** — only its internal pointer to the implementation does.  
This means your users always interact with the same proxy address, while you can safely upgrade logic.

## 🚀 Deploying to Sepolia

### 1. Deploy V1 + Proxy

```bash
forge script script/DeployBox.s.sol:DeployBox \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### 2. Check Version

```bash
cast call 0x096De44916a641f67f168475EA706A8d3053E36c \
"getVersion()(string)" --rpc-url $SEPOLIA_RPC_URL
# "v1"
```

### 3. Deploy + Upgrade Script

```bash
forge script script/UpgradeBox.s.sol:UpgradeBox \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### 4. Interacting With the Proxy, set new data

```bash
cast send 0x096De44916a641f67f168475EA706A8d3053E36c \
"setBox(uint256,string)" 28 "leticia" \
--rpc-url $SEPOLIA_RPC_URL \
--private-key $SEPOLIA_PRIVATE_KEY
```

### 5. Read updated state

```bash
cast call 0x096De44916a641f67f168475EA706A8d3053E36c \
"getBox()(uint256,string,uint256)" --rpc-url $SEPOLIA_RPC_URL
```

### Extra: Check which implementation proxy currently points to

```bash
cast storage 0x096De44916a641f67f168475EA706A8d3053E36c \
0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC0 \
--rpc-url $SEPOLIA_URL
```

## Verify Storage Layout

All state is stored in the **proxy**, not in the implementations.  
The storage layout must remain **consistent across versions** to prevent *storage clashes*.

### Safe Example

```solidity
// V1
uint256 number;

// V2
uint256 number; // same slot 0
string name;    // new slot 1
bool active;    // new slot 2
```

## Tools & Stack

- Foundry — scripting, testing, and on-chain execution
- OpenZeppelin Upgradeable Contracts — implements the UUPS pattern
- Sepolia Testnet — for real upgradeable contract testing

## Key Takeaways

- Users always interact only with the proxy.
- Proxy holds state, implementations hold logic.
- Maintain consistent storage layout between versions.
- Upgrades use upgradeToAndCall() through the UUPS pattern.
