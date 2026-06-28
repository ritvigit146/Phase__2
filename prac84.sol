// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: selfdestruct forces ETH into contract
CONCEPT: Forced balance behavior
=========================================================

OBJECTIVE

- Understand how selfdestruct can send ETH to any address
- Learn that ETH can be forced into contracts without payable functions
- Observe balance change without fallback/receive
- Learn historical + modern Ethereum behavior

=========================================================
CORE IDEA
=========================================================

selfdestruct(target) → sends ALL contract ETH to target

IMPORTANT:
No fallback() or receive() is required.

=========================================================
FORCED ETH CONTRACT (TARGET)
=========================================================
*/
contract VictimContractVul {

    uint256 public balanceTracker;

    function update() external payable {
        balanceTracker += msg.value;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /*
         Vulnerable

        Incorrectly assumes balanceTracker equals
        the actual ETH balance.
    */
    function withdrawAll() external {
        require(
            balanceTracker == address(this).balance,
            "Accounting mismatch"
        );

        payable(msg.sender).transfer(address(this).balance);

        balanceTracker = 0;
    }
}

/*
=========================================================
Attack Contract
=========================================================
*/

contract ForceEtherSenderVul {

    function forceSend(address payable target)
        external
        payable
    {
        selfdestruct(target);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy VictimContract

STEP 2:
Deploy ForceEtherSender

STEP 3:
Call:

forceSend(VictimContract, 5 ether)

=========================================================

STEP-BY-STEP RESULT
=========================================================

1. ForceEtherSender holds 5 ETH
2. selfdestruct executed
3. ALL ETH transferred to VictimContract
4. ForceEtherSender is destroyed

=========================================================
IMPORTANT OBSERVATION
=========================================================

VictimContract receives ETH:

- WITHOUT calling receive()
- WITHOUT calling fallback()
- WITHOUT user interaction

=========================================================
STATE IMPACT

address(victim).balance increases

BUT:

balanceTracker DOES NOT update automatically

=========================================================
WHY THIS IS IMPORTANT

Contracts cannot block selfdestruct ETH transfers.

=========================================================
REAL SECURITY IMPLICATIONS

This behavior affects:

- DAO accounting systems
- invariant checks
- balance-based logic
- reward calculations

=========================================================
AUDITOR INSIGHT

Auditors check:

✔ Can contract receive ETH unexpectedly?
✔ Does logic rely on msg.value only?
✔ Are balance assumptions trusted?
✔ Are invariants based on address(this).balance?

=========================================================
MODERN NOTE (IMPORTANT)

In newer Ethereum upgrades:
- selfdestruct behavior is being restricted
- but legacy behavior still matters for audits

=========================================================
COMMON BUGS CAUSED

- stuck accounting mismatches
- reward inflation/deflation bugs
- incorrect total supply assumptions
- invariant breakage in DeFi protocols

=========================================================
KEY TAKEAWAYS

- selfdestruct bypasses receive/fallback
- ETH can be forced into any contract
- balance != accounting state
- protocols must not fully trust address.balance
- forced ETH breaks assumptions in DeFi systems

=========================================================
*/
/*
Audit Report

Title: Forced Ether via selfdestruct Causes Accounting Mismatch

Severity: Medium because an attacker can force Ether into the contract using
selfdestruct(), causing the contract's actual ETH balance to differ from its
internal accounting. While this does not directly allow theft of funds, it
can break business logic, invariants, and balance-dependent operations.

Location:
Contract: VictimContractVul
Function: withdrawAll()

Vulnerability Description:

The contract maintains an internal accounting variable (balanceTracker) that
tracks deposits made through the update() function.

The withdrawAll() function assumes that:

```
balanceTracker == address(this).balance
```

This assumption is unsafe because Ether can be forced into the contract
without executing update(), receive(), or fallback() by using
selfdestruct() from another contract.

As a result, the contract's actual Ether balance can become larger than
balanceTracker, causing the equality check to fail and preventing
withdrawAll() from executing.

Impact:

An attacker can:

* force Ether into the contract using selfdestruct()
* break the accounting invariant
* cause withdrawAll() to revert permanently
* create denial-of-service conditions for balance-dependent logic
* disrupt protocols relying on address(this).balance for accounting

Although no funds are directly stolen, incorrect accounting may prevent
normal contract operation and affect protocol functionality.

Proof of Concept:

1. Deploy VictimContractVul.

2. Deposit 1 ETH by calling:

   update{value: 1 ether}()

State:

```
balanceTracker = 1 ETH
address(this).balance = 1 ETH
```

3. Deploy ForceEtherSenderVul.

4. Call:

   forceSend{value: 5 ether}(victimAddress)

5. ForceEtherSenderVul executes selfdestruct() and transfers 5 ETH to
   VictimContractVul.

State becomes:

```
balanceTracker = 1 ETH
address(this).balance = 6 ETH
```

6. Call:

withdrawAll()

The following check fails:

```
require(
    balanceTracker == address(this).balance,
    "Accounting mismatch"
);
```

The transaction reverts because the internal accounting no longer matches
the contract's actual Ether balance.

Root Cause:

The contract assumes that address(this).balance only changes through the
update() function.

However, Ether can be transferred to any contract through selfdestruct(),
mining rewards (historically), or other protocol mechanisms without executing
the contract's logic.

Therefore, address(this).balance must never be treated as a trusted accounting
source.

Recommendation:

Do not rely on address(this).balance for internal accounting.

Recommended mitigations include:

* maintain independent accounting variables for user deposits
* track balances using mappings and totalDeposits
* avoid equality checks between internal accounting and
  address(this).balance
* design business logic to tolerate unexpected Ether transfers
* treat address(this).balance only as the contract's actual Ether holdings,
  not as the authoritative accounting value

The patched contract correctly separates internal accounting
(totalDeposits) from the contract's actual Ether balance, preventing forced
Ether transfers from breaking contract logic.

*/

// Patched code
contract VictimContract {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {

        require(
            balances[msg.sender] >= amount,
            "Insufficient balance"
        );

        balances[msg.sender] -= amount;
        totalDeposits -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "Transfer failed");
    }

    /*
        Internal accounting.

        Forced Ether does NOT affect this value.
    */
    function accountingBalance()
        external
        view
        returns (uint256)
    {
        return totalDeposits;
    }

    /*
        Actual ETH held by contract.

        May be larger because of forced Ether.
    */
    function actualBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}

/*
=========================================================
Educational Attack Contract
=========================================================
*/

contract ForceEtherSender {

    function forceSend(address payable target)
        external
        payable
    {
        selfdestruct(target);
    }
}