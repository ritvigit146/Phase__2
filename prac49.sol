// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Reorder logic intentionally
CONCEPT: Vulnerability creation
=========================================================

OBJECTIVE

- Learn how bad execution order creates vulnerabilities
- Understand dangerous state-update sequencing
- Learn reentrancy-style ordering issues
- Think like a smart contract auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Execution order is SECURITY CRITICAL.

Changing line order may:
- break invariants
- expose reentrancy
- corrupt accounting
- enable fund theft

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Same logic
+
Different order
=
Completely different security outcome.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many real-world hacks happened because:
logic executed in wrong order.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Ordering mistakes affected:

- DAO hack
- lending protocols
- vault systems
- reward systems
- staking protocols
- AMMs

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- state-update order
- external-call timing
- validation placement
- stale-state reads
- invariant preservation

=========================================================
*/
contract ReorderLogicVul {

    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    mapping(address => uint256) public rewards;

    function safeDeposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "No ETH sent"
        );

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================

    External call before state update.
    Classic reentrancy vulnerability.
    */

    function vulnerableWithdraw(
        uint256 _amount
    )
        external
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            VULNERABILITY

            ETH transferred before balance update.
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        /*
            State updated too late.
        */
        balances[msg.sender] -= _amount;
        totalBalance -= _amount;
    }

    /*
    =====================================================
    VULNERABLE REWARD LOGIC
    =====================================================
    */

    function badRewardUpdate(
        uint256 _deposit
    )
        external
    {
        /*
            Stale state read.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        balances[msg.sender] += _deposit;
    }
}

/*
=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

BAD ORDER:
interaction before state update

=
classic reentrancy vulnerability.

=========================================================
SAFE WITHDRAW TRACE
=========================================================

CALL:
safeWithdraw(10)

=========================================================

STEP 1:
Balance check.

---------------------------------------------------------

STEP 2:
balances[Alice] -= 10

---------------------------------------------------------

STEP 3:
totalBalance -= 10

---------------------------------------------------------

STEP 4:
ETH transfer occurs LAST.

---------------------------------------------------------

SAFE:
state already updated.

=========================================================
VULNERABLE TRACE
=========================================================

CALL:
vulnerableWithdraw(10)

=========================================================

STEP 1:
Balance validated.

---------------------------------------------------------

STEP 2:
External ETH call occurs FIRST.

---------------------------------------------------------

DANGER:
Attacker contract can reenter NOW.

---------------------------------------------------------

STEP 3:
Balance reduced TOO LATE.

---------------------------------------------------------

ATTACK RESULT:
multiple withdrawals possible.

=========================================================
WHY REORDERING CREATES VULNERABILITIES
=========================================================

Security depends on:
WHEN state changes occur.

---------------------------------------------------------

Incorrect ordering may expose:
temporary inconsistent state.

=========================================================
REWARD BUG TRACE
=========================================================

INITIAL:

balances[Alice] = 100

---------------------------------------------------------

CALL:
badRewardUpdate(50)

---------------------------------------------------------

STEP 1:
Reward calculated.

100 / 10 = 10

---------------------------------------------------------

STEP 2:
Balance updated later.

balances[Alice] = 150

---------------------------------------------------------

FINAL:
Reward stale and incorrect.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
safeRewardUpdate(100)

---------------------------------------------------------

STEP 3:
Call:
rewards(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Deploy fresh contract

---------------------------------------------------------

STEP 5:
Call:
badRewardUpdate(100)

---------------------------------------------------------

STEP 6:
Call:
rewards(your_address)

EXPECTED:
0

---------------------------------------------------------

OBSERVE:
Wrong order caused stale calculation.

=========================================================
CRITICAL AUDITOR CONCEPT
=========================================================

Auditors care deeply about:

EXECUTION ORDER

---------------------------------------------------------

Because:
same code + different order
can create exploits.

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

SAFE PATTERN:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Prevents:
many reentrancy attacks.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. EXTERNAL CALL BEFORE STATE UPDATE
---------------------------------------------------------

Classic reentrancy risk.

---------------------------------------------------------
2. STALE STATE READS
---------------------------------------------------------

Logic reads outdated values.

---------------------------------------------------------
3. INVARIANT VIOLATIONS
---------------------------------------------------------

Temporary inconsistent state exposed.

---------------------------------------------------------
4. PARTIAL EXECUTION ASSUMPTIONS
---------------------------------------------------------

Incorrect ordering breaks accounting.

=========================================================
GAS OBSERVATION
=========================================================

Incorrect ordering may:
waste gas during revert paths.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What executes first?
- When is state updated?
- Are external calls dangerous?
- Can temporary state be abused?
- Are invariants preserved throughout execution?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker deploys malicious contract.

---------------------------------------------------------

During vulnerableWithdraw():

1. receives ETH
2. fallback triggers
3. reenters withdraw()
4. balance still unchanged
5. steals funds repeatedly

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Exact execution order
2. Storage update timing
3. External interaction timing
4. Revert points
5. Reentrancy windows

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add external token transfer
2. Intentionally place it before
   balance reduction
3. Analyze vulnerability
4. Fix using CEI pattern

BONUS:
Implement nonReentrant modifier.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Execution order is security critical
- Reordering logic can create vulnerabilities
- External calls before state updates are dangerous
- CEI pattern prevents many attacks
- Stale reads create incorrect accounting
- Temporary inconsistent state is exploitable
- Reentrancy depends heavily on ordering
- Auditors trace exact execution sequence
- Same logic with different order changes security
- Order dependency is fundamental to smart contract auditing

=========================================================
*/
/*
Audit Report

Title:
Reentrancy Vulnerability Due To Incorrect Execution Order

Severity:
High

Location:
Contract: ReorderLogicVulnerability
Function: vulnerableWithdraw()

Vulnerability Description:

The vulnerableWithdraw() function performs
an external ETH transfer before updating
user balances and protocol accounting.

This violates the Checks-Effects-Interactions
(CEI) security pattern.

Because the user's balance is not reduced
before the external call, an attacker can
reenter the function through a fallback()
or receive() function and execute multiple
withdrawals before storage is updated.

Impact:

An attacker may withdraw funds repeatedly
within the same transaction.

Potential consequences include:

- Theft of ETH
- Complete draining of contract funds
- Insolvency of protocol
- Corrupted accounting
- Loss of user funds

Proof of Concept:

1. Attacker deposits 10 ETH.

2. balances[attacker] = 10 ETH

3. Attacker calls:

   vulnerableWithdraw(1 ether)

4. Contract executes:

   call{value:1 ether}()

5. Attacker receives ETH.

6. Attacker fallback() executes.

7. fallback() calls:

   vulnerableWithdraw(1 ether)

8. Balance check passes again because:

   balances[attacker]
   still equals 10 ETH.

9. Process repeats multiple times.

10. Contract loses funds before
    balances are updated.

Root Cause:

The external interaction occurs before
critical state variables are updated.

The contract exposes an inconsistent
temporary state to external code.

Recommendation:

Apply the Checks-Effects-Interactions
pattern.

Recommended order:

1. Validate inputs
2. Update storage
3. Perform external calls

Additional protection:

Implement a nonReentrant modifier
to prevent nested execution.

Patched Example:

balances[msg.sender] -= _amount;
totalBalance -= _amount;

(bool success,) =
    payable(msg.sender).call{
        value:_amount
    }("");

require(success);

*/

// Patched code
contract ReorderLogic {

    mapping(address => uint256) public balances;
    uint256 public totalBalance;
    mapping(address => uint256) public rewards;

    bool private locked;

    modifier nonReentrant() {
        require(
            !locked,
            "Reentrant call"
        );

        locked = true;

        _;

        locked = false;
    }

    function safeDeposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "No ETH sent"
        );

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    /*
    =====================================================
    PATCHED WITHDRAW
    =====================================================

    Uses:
    Checks -> Effects -> Interactions
    */

    function withdraw(
        uint256 _amount
    )
        external
        nonReentrant
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
            EFFECTS FIRST
        */
        balances[msg.sender] -= _amount;
        totalBalance -= _amount;

        /*
            INTERACTION LAST
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );
    }

    /*
    =====================================================
    PATCHED REWARD LOGIC
    =====================================================
    */

    function rewardUpdate(
        uint256 _deposit
    )
        external
    {
        /*
            Update balance first.
        */
        balances[msg.sender] += _deposit;

        /*
            Reward uses latest balance.
        */
        rewards[msg.sender] =
            balances[msg.sender] / 10;
    }
}