# Foundry Projects & Key Takeaways

My Foundry playground!

This repository is my main hub for learning and building smart contracts using the Foundry framework. It includes test-driven development, Chainlink integrations, and my journey as smart contract developer.

This repo contains both practice snippets and fully implemented smart contract projects. I use it to:

- Learn and document Foundry-specific CLI tools
- Build and test smart contracts in Solidity
- Work with Chainlink VRF & Automation
- Explore best practices in smart contract security and testing

## 📂 Repo Structure

| Folder/File              | Description |
|---------------------------|-------------|
| `airdrops-signatures/`    | Experiments with EIP-712 signatures, Merkle proofs, and secure airdrop verification flows. |
| `fund-me-contract/`       | Funding contract integrating Chainlink price feeds and subscription refactor for VRF v2 Plus. |
| `raffle-contract/`        | Chainlink VRF v2.5 raffle project with automated winner selection and randomness logic. |
| `simple-storage/`         | Foundational practice contract — state variable setting, events, and timestamps. |
| `upgradable-contracts/`   | UUPS + ERC1967 Proxy upgradeable contracts — deployment, upgrade, and verification flow on Sepolia. |
| `basics1.sol`             | Personal cheat sheet — Forge, Cast, Anvil commands and Solidity notes built through hands-on learning. |

## Contract-Only Projects

These subfolders (`raffle-contract/`, `fund-me-contract/`and `simple-storage/`) includes:

- `/src`: Contract logic
- `/test`: Unit + integration tests
- `/script`: Deployment logic
- `/lib/chainlink/...`: Chainlink contracts & interfaces

## Stack

- **Solidity** & Foundry (`forge`, `cast`, `anvil`)
- **Chainlink VRF & Automation**
- **Testing**: Mocks, fuzzing, error handling, and fork testing
- **GitHub** for version control, commits, and sharing progress

## 🌱 Why This Repo Matters

This repo reflects real learning, my journey through Foundry. It documents not just the code but the lessons I’m learning along the way.
