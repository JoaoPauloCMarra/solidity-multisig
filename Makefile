# shortcuts for common commands
-include .env

.PHONY: all test clean deploy

all: clean build

build:
	forge build

test:
	forge test

test-v:
	forge test -vvv

gas:
	forge test --gas-report

snapshot:
	forge snapshot

clean:
	forge clean

# local dev with anvil
anvil:
	anvil

deploy-local:
	forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# testnet
deploy-sepolia:
	forge script script/Deploy.s.sol --rpc-url $(SEPOLIA_RPC_URL) --broadcast --verify

# demo flow (run after deploy-local)
WALLET := 0x5FbDB2315678afecb367f032d93F642f64180aa3
KEY0 := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
KEY1 := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

demo-submit:
	cast send $(WALLET) "submit(address,uint256,bytes)" \
		0x1234567890123456789012345678901234567890 100000000000000000 0x \
		--private-key $(KEY0)

demo-confirm-1:
	cast send $(WALLET) "confirm(uint256)" 0 --private-key $(KEY0)

demo-confirm-2:
	cast send $(WALLET) "confirm(uint256)" 0 --private-key $(KEY1)

demo-execute:
	cast send $(WALLET) "execute(uint256)" 0 --private-key $(KEY0)

demo-status:
	cast call $(WALLET) "getTransaction(uint256)" 0
