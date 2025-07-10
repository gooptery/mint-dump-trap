# 🛡️ MintDumpTrap
MintDumpTrap is a trap smart contract for the Drosera Network, designed to detect malicious ERC20 token behavior, especially the mint-and-dump pattern. It uses on-chain Transfer log data to identify suspicious activity in token lifecycles.

---

## MintDumpTrap.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    function balanceOf(address account) external view returns (uint256);
}

contract MintDumpTrap is ITrap {
    address public tokenContract;

    struct TransferEvent {
        address from;
        address to;
        uint256 amount;
    }

    constructor() {
        address hardcodedToken = 0x499b095Ed02f76E56444c242EC43A05F9c2A3ac8; //TOKEN ADDRESS
        require(hardcodedToken != address(0), "Invalid token contract address");
        tokenContract = hardcodedToken;
    }

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.timestamp, block.number);
    }

    function shouldRespond(bytes[] calldata _data) external pure override returns (bool should, bytes memory reason) {
    if (_data.length == 0) {
        return (false, "No input data provided.");
    }
    if (_data.length < 2) {
        return (false, "Missing Transfer events data from off-chain client");
    }

    TransferEvent[] memory logs = abi.decode(_data[1], (TransferEvent[]));
    if (logs.length > 50) {
        return (false, "Too many logs.");
    }

    for (uint i = 0; i < logs.length; i++) {
        TransferEvent memory mintLog = logs[i];
        if (mintLog.from == address(0)) {
            for (uint j = i + 1; j < logs.length; j++) {
                TransferEvent memory dumpLog = logs[j];

                if (
                    dumpLog.from == mintLog.to &&
                    dumpLog.amount == mintLog.amount &&
                    dumpLog.to != address(0)
                ) {
                    should = true;
                    reason = abi.encode(
                        keccak256("TOKEN_DUMP_DETECTED"),
                        mintLog.to,
                        dumpLog.to,
                        mintLog.amount
                    );
                    return (should, reason);
                  }
              }
          }
      }

      should = false;
      reason = "No suspicious mint-dump detected.";
    }
}
```

## 🎯 Use Case: Detecting Mint-and-Dump Scams
A typical mint-and-dump pattern involves:

```vbnet
┌────────────┐
│  Minting   │   Transfer from: 0x0
└─────┬──────┘
      │
      ▼
┌──────────────┐
│  Wallet X    │   receives mint
└─────┬────────┘
      │
      ▼
┌──────────────┐
│ Immediate    │   Transfer to: DEX / bridge / victim
│  Dump        │
└──────────────┘
```

This trap contract monitors for a mint (from address(0)) followed by an immediate transfer of the same amount from the recipient, which signals a potential scam.

---

## ✅ Example Detection Flow
Given the following logs:

```json
[
  {
    "from": "0x0000000000000000000000000000000000000000",
    "to": "0xBADBEEF",
    "amount": "100000000000000000000"
  },
  {
    "from": "0xBADBEEF",
    "to": "0xDEX12345",
    "amount": "100000000000000000000"
  }
]
```

The trap will match the following:

- *mint detected to 0xBADBEEF*

- *same amount immediately transferred to another address (0xDEX12345)*

→ Result: shouldRespond() returns true with reason:

```solidity
keccak256("TOKEN_DUMP_DETECTED")
```
---

## ⚠️ Real-World Scenarios

### 🧪 Airdrop Abuse
An address receives an airdrop and immediately dumps the tokens on a DEX—indicating a wash trade or token manipulation.

### 🎣 Honeypot Token Scam
A malicious dev mints tokens to their own wallet, immediately transfers or sells them to bait buyers, and later prevents selling.

### 🔁 Cross-Chain Dumping
Tokens are minted and rapidly sent to bridge contracts to simulate value across chains or evade detection.

### 🤖 Wash Trading Bots
Bots simulate fake market volume by minting and flipping tokens between controlled wallets.

---

## ✅ When to Use This Trap
1. To detect scam tokens early before they gain traction.

2. To monitor suspicious deployer activity after a token launch.

3. As part of automated transaction scoring in the Drosera operator stack.

---

## 🔗 Integration with Drosera Operator
You can integrate MintDumpTrap in the operator’s trap registry:

1. Deploy the trap contract.

2. Register using drosera-operator register.

```solidity
drosera-operator register \
  --trap-address <deployed-address> \
  --eth-rpc-url <your-RPC> \
  --eth-private-key <your-key>
```

3. The Drosera node will:

- Call collect() to simulate or fetch token logs.

- Feed logs into shouldRespond().

- Trigger dispute if result is true.

---

## 📝 Output Format
- Return: bool shouldRespond, bytes reason

- *Reason* (if suspicious):

```solidity
abi.encode(
    keccak256("TOKEN_DUMP_DETECTED"),
    mintRecipient,
    dumpDestination,
    tokenAmount
)
```

- *Reason* (if not suspicious):

```solidity
"No suspicious mint-dump detected."
```

---

## 📌 Notes
- This trap is stateless and gas-efficient.

- Designed for local analysis — no external calls.

- Ideal for early detection of token scams in real-time.

---
