# Multi-Sig Wallet

A minimal, gas-optimized multi-signature wallet built with Foundry.

## Features

- **Threshold-based execution**: configurable M-of-N signature requirement
- **Transaction lifecycle**: submit → confirm → execute (or revoke)
- **Owner management**: add/remove owners via wallet transactions
- **Custom errors**: gas-efficient reverts with clear failure reasons
- **No external dependencies**: zero OpenZeppelin imports

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     MultiSigWallet                          │
├─────────────────────────────────────────────────────────────┤
│  owners[]          - array of authorized signers            │
│  isOwner{}         - O(1) ownership lookup                  │
│  threshold         - required confirmations                 │
│  transactions[]    - pending/executed tx queue              │
│  isConfirmed{}     - per-tx confirmation tracking           │
├─────────────────────────────────────────────────────────────┤
│  submit()          - propose new transaction                │
│  confirm()         - add confirmation                       │
│  revoke()          - remove confirmation                    │
│  execute()         - run if threshold met                   │
│  addOwner()        - wallet-only                            │
│  removeOwner()     - wallet-only                            │
│  changeThreshold() - wallet-only                            │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# install deps
forge install

# run tests
make test

# verbose output
make test-v

# gas report
make gas
```

## Local Demo

```bash
# terminal 1: start local chain
make anvil

# terminal 2: deploy
make deploy-local

# run the demo flow
make demo-submit      # propose tx
make demo-confirm-1   # owner 1 confirms
make demo-confirm-2   # owner 2 confirms
make demo-execute     # execute (threshold met)
make demo-status      # check result
```

## Deploy to Sepolia

1. Copy `.env.example` to `.env` and fill in values:

```bash
PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://...
ETHERSCAN_API_KEY=...
OWNER_1=0x...
OWNER_2=0x...
OWNER_3=0x...
THRESHOLD=2
```

2. Deploy:

```bash
make deploy-sepolia
```

## Usage

### Submit a transaction

```solidity
wallet.submit(recipient, value, data);
```

### Confirm

```solidity
wallet.confirm(txId);
```

### Execute (when threshold met)

```solidity
wallet.execute(txId);
```

### Manage owners (requires wallet tx)

```solidity
// encode the call
bytes memory data = abi.encodeWithSelector(MultiSigWallet.addOwner.selector, newOwner);

// submit as wallet transaction
wallet.submit(address(wallet), 0, data);
// ... confirm and execute
```

## Security

- **Checks-effects-interactions**: state updates before external calls
- **Custom errors**: cheaper than string reverts
- **No reentrancy risk**: `executed` flag set before call

## License

MIT
