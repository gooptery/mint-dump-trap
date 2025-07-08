# 🧪 MintDumpTrap Tests
This document outlines the unit tests for the MintDumpTrap contract, which is designed to detect suspicious mint-and-dump behavior in ERC20 tokens.

---

## 🔧 Setup
*Ensure you have Foundry installed.*

Run the tests with:

```bash
forge test
```

---

## ✅ Test Cases
### 1. testShouldRespondWhenMintAndDump()
✔️ Purpose: Detect a classic mint followed by an immediate dump.

**🧪 Input:**

Mint: from: 0x0 → to: 0xBADBEEF

Dump: from: 0xBADBEEF → to: 0xCAFEBABE (same amount)

**✅ Expectation:**

shouldRespond == true

reason == abi.encode(keccak256("TOKEN_DUMP_DETECTED"), from, to, amount)

---


### 2. testShouldNotRespondWhenOnlyMinted()
✔️ Purpose: Ensure no response if mint happens without a dump.

**🧪 Input:**

One mint log to 0xBADBEEF

**✅ Expectation:**

shouldRespond == false

Reason: "No suspicious mint-dump detected."

---


### 3. testShouldNotRespondWithNoData()
✔️ Purpose: Check input validation when no logs are provided.

**🧪 Input:** []

**✅ Expectation:**

Should revert with: "No input data provided."

---


### 4. testShouldNotRespondWithTooManyLogs()
✔️ Purpose: Enforce upper limit on log size (gas-safe bound).

**🧪 Input:**

51 dummy logs

**✅ Expectation:**

Should revert with: "Too many logs."

---

### 5. testShouldNotRespondWhenNoMint()
✔️ Purpose: Ensure the trap does not trigger when no mint is present.

**🧪 Input:**

Normal transfer: 0x1111 → 0x2222 → 0x3333

**✅ Expectation:**

shouldRespond == false

reason == "No suspicious mint-dump detected."

---

### 6. testShouldNotRespondWhenMintButNoMatchingDump()
✔️ Purpose: Catch cases where the mint occurs but the dump is unrelated.

**🧪 Input:**

Mint to 0xABCDEF

Dump from 0x123456 (not matching the minter)

**✅ Expectation:**

shouldRespond == false

reason == "No suspicious mint-dump detected."

---

![Screenshot 2025-07-08 125832](https://github.com/user-attachments/assets/1e24ce82-b999-4b70-883b-7d6da3446cd7)
