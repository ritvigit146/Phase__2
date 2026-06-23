// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Update state before require
CONCEPT: State rollback behavior
=========================================================

OBJECTIVE

- Learn what happens when require() fails
- Understand transaction rollback behavior
- Learn EVM atomicity guarantees
- Understand why reverted state changes disappear

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If require() fails:

ALL state changes in the transaction
are reverted automatically.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if storage was updated BEFORE require():

A revert undoes everything.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

This is one of the MOST IMPORTANT
EVM security guarantees.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Rollback behavior protects:

- balances
- token transfers
- DeFi accounting
- governance state
- auction logic

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution order
- state updates before external calls
- revert handling
- atomicity assumptions
- partial-update risks

=========================================================
*/
contract StateRollbackBehaviorVul {

    uint256 public totalCounter;

    mapping(address => uint256) public userCounter;

    function riskyIncrement(
        uint256 _value
    )
        external
    {
        // Storage writes occur first
        totalCounter += _value;

        userCounter[msg.sender] += _value;

        // Validation happens later
        require(
            _value <= 10,
            "Value too large"
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

totalCounter = 0

userCounter[Alice] = 0

=========================================================
TRACE:
riskyIncrement(5)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

totalCounter =
0 + 5

NEW VALUE:
5

---------------------------------------------------------
STEP 2
---------------------------------------------------------

userCounter[Alice] =
0 + 5

NEW VALUE:
5

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(5 <= 10)

RESULT:
true

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

totalCounter = 5

userCounter[Alice] = 5

=========================================================
TRACE:
riskyIncrement(50)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

totalCounter =
5 + 50

TEMP VALUE:
55

---------------------------------------------------------
STEP 2
---------------------------------------------------------

userCounter[Alice] =
5 + 50

TEMP VALUE:
55

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(50 <= 10)

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

ALL STATE CHANGES UNDONE.

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

totalCounter = 5

userCounter[Alice] = 5

---------------------------------------------------------

IMPORTANT:
Temporary updates disappear.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
riskyIncrement(5)

---------------------------------------------------------

STEP 3:
Call:
totalCounter()

EXPECTED:
5

---------------------------------------------------------

STEP 4:
Call:
riskyIncrement(50)

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 5:
Call:
totalCounter()

EXPECTED:
Still 5

---------------------------------------------------------

STEP 6:
Call:
userCounter(your_address)

EXPECTED:
Still 5

---------------------------------------------------------

OBSERVE:
Failed transaction changed NOTHING.

=========================================================
IMPORTANT EVM UNDERSTANDING
=========================================================

ETHEREUM TRANSACTIONS ARE:

ATOMIC

---------------------------------------------------------

Meaning:

Either:
- EVERYTHING succeeds

OR:
- EVERYTHING reverts

=========================================================
ROLLBACK MECHANISM
=========================================================

When require() fails:

EVM:
- discards storage writes
- discards state changes
- refunds remaining gas
- reverts execution

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

TEMPORARY STORAGE CHANGES
can exist DURING execution.

---------------------------------------------------------

BUT:
they disappear after revert.

=========================================================
WHY VALIDATION-FIRST IS BETTER
=========================================================

THIS IS PREFERRED:

1. validate
2. update state

---------------------------------------------------------

Reason:
Avoid wasted computation/gas.

=========================================================
BAD PATTERN
=========================================================

1. update storage
2. validate later

---------------------------------------------------------

Problem:
Wasted gas if revert occurs.

=========================================================
GAS OBSERVATION
=========================================================

REVERTS:
Undo state changes

---------------------------------------------------------

BUT:
Gas already consumed is NOT fully refunded.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. VALIDATE BEFORE STATE CHANGES
---------------------------------------------------------

Auditors prefer:
Checks -> Effects -> Interactions

---------------------------------------------------------
2. UNDERSTAND ATOMICITY
---------------------------------------------------------

Partial state updates cannot persist
after revert.

---------------------------------------------------------
3. EXTERNAL CALL RISKS
---------------------------------------------------------

If external calls happen before revert,
complex behaviors may occur.

---------------------------------------------------------
4. GAS WASTAGE
---------------------------------------------------------

Late validation wastes gas.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker intentionally triggers reverts
after expensive computation.

Result:
Gas griefing / DOS potential.

---------------------------------------------------------

ANOTHER RISK

Incorrect assumptions about rollback
may create accounting vulnerabilities.

=========================================================
REAL AUDITOR PATTERN
=========================================================

AUDITORS TRACE:

1. What changes first?
2. What can revert?
3. Are external calls involved?
4. Can partial execution leak effects?
5. Is CEI pattern followed?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw() function
2. Update balance before require()
3. Observe rollback manually
4. Then rewrite using:
Checks -> Effects -> Interactions

BONUS:
Add custom errors instead of require strings.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Ethereum transactions are atomic
- require() failure reverts all state changes
- Storage updates disappear after revert
- Temporary execution state exists internally
- Validation-first is preferred
- Late validation wastes gas
- Reverts undo storage writes
- CEI pattern improves security
- Auditors trace rollback behavior carefully
- State persistence only happens on success

=========================================================
*/
/*
Audit Report

Title: State Updates Performed Before Validation (Violation of Checks-Effects Pattern)

Severity: Low because the EVM correctly reverts all state
changes on failure, but unnecessary storage operations
increase gas costs and reduce efficiency.

Location:
Contract: StateRollbackBehavior
Function: riskyIncrement()

Vulnerability Description:

The riskyIncrement() function updates storage variables
before validating the user input.

Specifically, the function:

1. Updates totalCounter
2. Updates userCounter[msg.sender]
3. Executes a require() validation check

If the validation fails, Ethereum reverts the entire
transaction and restores the previous state.

Although this prevents permanent state corruption, the
contract still performs unnecessary storage reads and
writes before reverting.

This violates the recommended Checks → Effects →
Interactions (CEI) pattern.

Impact:

An attacker can repeatedly submit invalid inputs that
trigger transaction reverts after storage operations
have already been executed.

This results in:

- unnecessary gas consumption
- wasted computation
- reduced contract efficiency

No permanent loss of funds or state corruption occurs
because Ethereum transactions are atomic.

Proof of Concept:

1. Deploy contract

2. Call:

   riskyIncrement(50)

3. Execution:

   totalCounter = totalCounter + 50
   userCounter[msg.sender] += 50

4. Validation executes:

   require(50 <= 10)

5. Validation fails

6. Transaction reverts

7. Storage returns to original values

8. Gas spent before the revert is lost

Root Cause:

Input validation is performed after state updates.

The function allows expensive storage operations to occur
before determining whether execution should proceed.

Recommendation:

Perform all validation checks before modifying state.

Example:

function safeIncrement(
    uint256 _value
)
    external
{
    require(
        _value <= 10,
        "Value too large"
    );

    totalCounter += _value;
    userCounter[msg.sender] += _value;
}

Additionally, consider using custom errors instead of
require strings for improved gas efficiency.

Example:

error ValueTooLarge();

if (_value > 10) {
    revert ValueTooLarge();
}

This follows the Checks → Effects → Interactions pattern
and avoids unnecessary storage operations when validation
fails.
*/
//Patched code
contract StateRollbackBehaviorPatched {

    error ValueTooLarge();

    uint256 public totalCounter;

    mapping(address => uint256) public userCounter;

    function safeIncrement(
        uint256 _value
    )
        external
    {
        // CHECKS
        if (_value > 10) {
            revert ValueTooLarge();
        }

        // EFFECTS
        totalCounter += _value;

        userCounter[msg.sender] += _value;
    }
}