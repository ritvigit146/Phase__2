// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger revert manually
CONCEPT: Full rollback
=========================================================

OBJECTIVE

- Learn how revert() works
- Understand manual transaction rollback
- Learn EVM atomicity behavior
- Understand state restoration after revert

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

revert() immediately:
- stops execution
- undoes ALL state changes
- returns remaining gas

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if storage was modified BEFORE revert():

ALL changes are undone.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Manual revert is critical for:

- validation
- invariant enforcement
- protocol safety
- emergency protection

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

revert() used in:

- DeFi protocols
- ERC20 tokens
- staking systems
- governance logic
- liquidation engines
- vault protections

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- revert conditions
- rollback guarantees
- partial execution risks
- state consistency
- revert message clarity

=========================================================
*/
contract ManualRevertExampleVul {

    uint256 public totalCounter;

    mapping(address => uint256) public balances;

    function dangerousDeposit(
        uint256 _amount
    )
        external
    {
        /*
            STATE UPDATED FIRST
        */
        balances[msg.sender] += _amount;
        totalCounter += _amount;

        /*
            VALIDATION HAPPENS LATE
        */
        if (_amount > 10) {
            revert("Amount exceeds limit");
        }
    }

    function onlyEven(
        uint256 _number
    )
        external
        pure
        returns (string memory)
    {
        if (_number % 2 != 0) {
            revert("Odd number rejected");
        }

        return "Even number accepted";
    }

    function silentRevert(
        bool _shouldFail
    )
        external
        pure
    {
        if (_shouldFail) {
            revert();
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

balances[Alice] = 0

totalCounter = 0

=========================================================
TRACE:
dangerousDeposit(5)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

balances[Alice] += 5

TEMP VALUE:
5

---------------------------------------------------------

totalCounter += 5

TEMP VALUE:
5

---------------------------------------------------------
STEP 2
---------------------------------------------------------

if (_amount > 10)

CHECK:
5 > 10

RESULT:
false

---------------------------------------------------------

NO REVERT OCCURS

---------------------------------------------------------

TRANSACTION SUCCEEDS

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 5

totalCounter = 5

=========================================================
REVERT TRACE
=========================================================

CALL:
dangerousDeposit(50)

=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

balances[Alice] += 50

TEMP VALUE:
55

---------------------------------------------------------

totalCounter += 50

TEMP VALUE:
55

---------------------------------------------------------
STEP 2
---------------------------------------------------------

CHECK:
50 > 10

RESULT:
true

---------------------------------------------------------

revert("Amount exceeds limit")

---------------------------------------------------------

TRANSACTION STOPS IMMEDIATELY

---------------------------------------------------------

ALL STATE CHANGES ROLLBACK

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 5

totalCounter = 5

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
dangerousDeposit(5)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
5

---------------------------------------------------------

STEP 4:
Call:
dangerousDeposit(50)

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
balances(your_address)

EXPECTED:
Still 5

---------------------------------------------------------

STEP 6:
Call:
totalCounter()

EXPECTED:
Still 5

---------------------------------------------------------

OBSERVE:
Failed transaction changed NOTHING.

---------------------------------------------------------

STEP 7:
Call:
onlyEven(4)

EXPECTED:
"Even number accepted"

---------------------------------------------------------

STEP 8:
Call:
onlyEven(5)

EXPECTED:
Revert

=========================================================
IMPORTANT REVERT UNDERSTANDING
=========================================================

revert() immediately:

- stops execution
- undoes state changes
- restores previous state

=========================================================
EVM ATOMICITY
=========================================================

Ethereum transactions are:

ATOMIC

---------------------------------------------------------

Meaning:

Either:
- everything succeeds

OR:
- everything reverts

=========================================================
REVERT VS RETURN
=========================================================

---------------------------------------------------------
RETURN
---------------------------------------------------------

- stops execution
- keeps state changes

---------------------------------------------------------
REVERT
---------------------------------------------------------

- stops execution
- undoes state changes

=========================================================
REVERT VS REQUIRE
=========================================================

require(condition, "msg")

is internally similar to:

if (!condition) {
    revert("msg");
}

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING REVERTS
---------------------------------------------------------

Invalid state may persist.

---------------------------------------------------------
2. LATE REVERTS
---------------------------------------------------------

Gas wasted after expensive computation.

---------------------------------------------------------
3. EXTERNAL CALL BEFORE REVERT
---------------------------------------------------------

Dangerous execution ordering.

---------------------------------------------------------
4. UNCLEAR ERROR REASONS
---------------------------------------------------------

Poor debugging visibility.

=========================================================
GAS OBSERVATION
=========================================================

revert():
refunds REMAINING gas only.

---------------------------------------------------------

Gas already consumed:
is NOT recovered.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What conditions trigger revert?
- Does rollback fully restore state?
- Can partial execution escape?
- Are invariants protected?
- Are revert reasons meaningful?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker intentionally triggers:
expensive computation + revert.

Result:
gas griefing DOS.

---------------------------------------------------------

ANOTHER RISK

Improper external-call ordering
before revert may expose vulnerabilities.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. State before revert
2. State after revert
3. Execution ordering
4. External interactions
5. Rollback guarantees

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw() function
2. Revert on insufficient balance
3. Add custom errors
4. Compare gas with require()

BONUS:
Implement invariant check:
that reverts on corruption.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- revert() manually stops execution
- revert() undoes all state changes
- Ethereum transactions are atomic
- Temporary storage updates disappear after revert
- revert() and require() are closely related
- return() and revert() behave differently
- Reverted transactions still consume gas
- Execution order matters heavily
- Auditors verify rollback guarantees
- Full rollback is critical for protocol safety

=========================================================
*/
/*
Audit Report

Title: Validation Performed After State Updates in dangerousDeposit()

Severity: Low

Location:
Contract: ManualRevertExample
Function: dangerousDeposit()

Vulnerability Description:

The dangerousDeposit() function updates the balances mapping
and totalCounter state variable before validating whether
the deposit amount exceeds the allowed limit.

Code:

balances[msg.sender] += _amount;
totalCounter += _amount;

if (_amount > 10) {
    revert("Amount exceeds limit");
}

Although the revert statement correctly restores the
previous state due to Ethereum transaction atomicity,
the contract performs unnecessary state modifications
before validating user input.

This violates the Checks-Effects pattern and may become
dangerous if future versions introduce external calls
before the revert condition.

Impact:

Current Impact:
- No permanent state corruption
- No unauthorized fund creation
- No loss of funds

Potential Future Impact:
- Increased gas consumption
- Poor code maintainability
- Higher audit complexity
- Potential security risks if external interactions are
  added before the revert condition

An attacker can repeatedly trigger failing transactions,
forcing unnecessary computation and storage operations.

Proof of Concept:

1. Deploy contract

2. Call:
   dangerousDeposit(5)

   Result:
   balances[msg.sender] = 5
   totalCounter = 5

3. Call:
   dangerousDeposit(50)

4. Execution performs:

   balances[msg.sender] += 50
   totalCounter += 50

5. Condition evaluates:

   50 > 10

6. revert("Amount exceeds limit") executes

7. Transaction rolls back completely

8. Final state remains:

   balances[msg.sender] = 5
   totalCounter = 5

Observation:

Storage writes occurred before validation and were
subsequently reverted.

Root Cause:

The function performs state-changing operations before
checking whether the input satisfies protocol rules.

The execution order is:

1. Effects
2. Validation
3. Revert

instead of:

1. Validation
2. Effects

Recommendation:

Perform validation before modifying storage.

Example:

if (_amount > 10) {
    revert("Amount exceeds limit");
}

balances[msg.sender] += _amount;
totalCounter += _amount;

Alternatively, use a custom error:

error AmountExceedsLimit();

if (_amount > 10) {
    revert AmountExceedsLimit();
}

This reduces gas costs and follows Solidity best
practices.

Status:

Confirmed

Risk Rating:

Low

*/

// Patched code
contract ManualRevertExamplePatched {

    uint256 public totalCounter;

    mapping(address => uint256) public balances;

    error AmountExceedsLimit();
    error OddNumberRejected();
    error OperationFailed();

    function dangerousDeposit(
        uint256 _amount
    )
        external
    {
        /*
            VALIDATE FIRST
        */
        if (_amount > 10) {
            revert AmountExceedsLimit();
        }

        /*
            UPDATE STATE AFTER VALIDATION
        */
        balances[msg.sender] += _amount;
        totalCounter += _amount;
    }

    function onlyEven(
        uint256 _number
    )
        external
        pure
        returns (string memory)
    {
        if (_number % 2 != 0) {
            revert OddNumberRejected();
        }

        return "Even number accepted";
    }

    function silentRevert(
        bool _shouldFail
    )
        external
        pure
    {
        if (_shouldFail) {
            revert OperationFailed();
        }
    }
}