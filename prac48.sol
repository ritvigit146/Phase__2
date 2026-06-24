// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call multiple state updates
CONCEPT: Order dependency
=========================================================

OBJECTIVE

- Learn how multiple storage updates execute
- Understand order dependency in Solidity
- Learn why update sequence matters
- Understand state consistency risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

State updates execute:
line-by-line in exact order.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Changing execution order can:
completely change final state.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Incorrect update ordering causes:

- accounting bugs
- balance corruption
- reentrancy vulnerabilities
- invariant violations

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Order dependency matters in:

- ERC20 transfers
- DeFi lending
- staking systems
- liquidation engines
- AMMs
- vault accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- update sequencing
- external-call ordering
- invariant preservation
- partial state assumptions
- race-condition risks

=========================================================
*/
contract OrderDependencyVul {

    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    mapping(address => uint256) public rewards;

    function depositWrong(
        uint256 _amount
    )
        external
    {
        require(_amount > 0, "Invalid amount");

        // VULNERABILITY:
        // Uses stale balance before deposit.
        rewards[msg.sender] =
            balances[msg.sender] / 10;

        balances[msg.sender] += _amount;

        totalSupply += _amount;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

balances[Alice] = 100

rewards[Alice] = 0

=========================================================
TRACE:
depositCorrect(50)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(50 > 0)

RESULT:
true

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
STEP 3
---------------------------------------------------------

totalSupply += 50

---------------------------------------------------------
STEP 4
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

150 / 10 = 15

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 15

=========================================================
BAD ORDER TRACE
=========================================================

INITIAL:

balances[Alice] = 100

---------------------------------------------------------

CALL:
depositWrong(50)

---------------------------------------------------------
STEP 1
---------------------------------------------------------

rewards[Alice] =
balances[Alice] / 10

100 / 10 = 10

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] += 50

NEW VALUE:
150

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 150

rewards[Alice] = 10

---------------------------------------------------------

IMPORTANT:
Reward incorrect because
order was wrong.

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Solidity executes:
TOP -> DOWN

---------------------------------------------------------

Every storage update affects:
future lines immediately.

=========================================================
ORDER DEPENDENCY
=========================================================

Later logic depends on:
earlier state changes.

---------------------------------------------------------

Changing line order may:
change protocol behavior.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
depositCorrect(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
rewards(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 5:
Deploy fresh contract

---------------------------------------------------------

STEP 6:
Call:
depositWrong(100)

---------------------------------------------------------

STEP 7:
Call:
rewards(your_address)

EXPECTED:
0

---------------------------------------------------------

OBSERVE:
Reward used OLD balance.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Incorrect update order can create:

- stale reads
- broken accounting
- exploit opportunities

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Known as:
CEI pattern.

=========================================================
WHY CEI MATTERS
=========================================================

Correct ordering helps prevent:
reentrancy vulnerabilities.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STALE STATE READS
---------------------------------------------------------

Logic reads old values accidentally.

---------------------------------------------------------
2. EXTERNAL CALL BEFORE UPDATE
---------------------------------------------------------

Major reentrancy risk.

---------------------------------------------------------
3. INVARIANT BREAKAGE
---------------------------------------------------------

Incorrect order corrupts accounting.

---------------------------------------------------------
4. DOUBLE-SPEND RISKS
---------------------------------------------------------

Incorrect balance sequencing dangerous.

=========================================================
GAS OBSERVATION
=========================================================

More state updates:
higher gas usage.

---------------------------------------------------------

Repeated storage reads/writes:
especially expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What updates happen first?
- Which values depend on prior state?
- Are stale reads possible?
- Are invariants preserved?
- Does execution order prevent exploits?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

External call before balance reduction.

Attacker reenters repeatedly.

Result:
fund theft.

---------------------------------------------------------

ANOTHER RISK

Reward calculated before update.

Attacker gains incorrect rewards.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Exact execution order
2. Storage reads/writes
3. Dependency chains
4. External-call timing
5. Invariant preservation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw function
2. Intentionally place external call
   before balance update
3. Observe vulnerability risk
4. Fix using CEI pattern

BONUS:
Track previousBalance and newBalance.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Solidity executes line-by-line
- State updates affect later execution immediately
- Execution order changes final behavior
- Incorrect ordering creates vulnerabilities
- CEI pattern improves security
- Stale reads are dangerous
- External-call ordering is critical
- Auditors trace exact state-update sequence
- Dependency chains matter heavily
- Order dependency is fundamental in smart contracts

=========================================================
*/
/*
Audit Report

Title: Incorrect State Update Order Causes Stale Reward Calculation

Severity: Low

Location:
Contract: OrderDependencyExample
Function: depositWrong()

Vulnerability Description:

The depositWrong() function calculates user rewards
before updating the user's balance.

As a result, rewards are derived from an outdated
balance value rather than the new balance after the
deposit has been processed.

This creates inconsistent accounting and violates
the expected business logic.

Impact:

Users may receive incorrect rewards.

If rewards represent:

- protocol incentives
- staking rewards
- governance points
- loyalty bonuses

then users may be under-rewarded or over-rewarded
depending on the execution flow.

Proof of Concept:

1. Assume:

   balances[Alice] = 100

2. Alice calls:

   depositWrong(50)

3. Function executes:

   rewards[Alice] = 100 / 10 = 10

4. Balance updated:

   balances[Alice] = 150

5. Final state:

   rewards[Alice] = 10

Expected:

   rewards[Alice] = 15

Root Cause:

Reward calculation is performed before
the balance update.

The function reads stale state and computes
rewards using an outdated value.

Recommendation:

Follow proper state-update ordering.

Update balances before computing values
that depend on those balances.

Example:

balances[msg.sender] += _amount;

rewards[msg.sender] =
    balances[msg.sender] / 10;

This ensures reward calculations use the
latest state.

*/

// Patched code
contract OrderDependencyPatched {

    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    mapping(address => uint256) public rewards;

    function deposit(
        uint256 _amount
    )
        external
    {
        require(_amount > 0, "Invalid amount");

        // EFFECT 1:
        balances[msg.sender] += _amount;

        // EFFECT 2:
        totalSupply += _amount;

        // EFFECT 3:
        rewards[msg.sender] =
        balances[msg.sender] / 10;
    }
}