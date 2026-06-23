// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fail require after state update
CONCEPT: Transaction atomicity
=========================================================

OBJECTIVE

- Learn Ethereum transaction atomicity
- Understand rollback after require() failure
- Observe temporary vs permanent state changes
- Learn why partial updates cannot persist

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

If require() fails:

EVERYTHING inside the transaction
is reverted.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even if:
- storage updated
- balances changed
- counters incremented

A revert removes ALL changes.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Atomicity is a core EVM guarantee.

Without atomicity:
partial state corruption would occur.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Atomicity protects:

- ERC20 transfers
- DeFi accounting
- lending protocols
- AMMs
- auctions
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- state updates before revert points
- external call ordering
- partial execution assumptions
- transaction rollback behavior
- CEI pattern compliance

=========================================================
*/

contract TransactionAtomicity {

    /*
        STORAGE VARIABLES

        Persist only if transaction succeeds.
    */
    uint256 public globalCounter;

    mapping(address => uint256) public balances;

    /*
    =====================================================
    FAIL REQUIRE AFTER STATE UPDATE
    =====================================================
    */

    function brokenExecution(
        uint256 _amount
    )
        external
    {

        /*
            STEP 1:
            UPDATE GLOBAL COUNTER

            Temporary state update.
        */
        globalCounter =
            globalCounter + _amount;

        /*
            STEP 2:
            UPDATE USER BALANCE

            Temporary state update.
        */
        balances[msg.sender] =
            balances[msg.sender] + _amount;

        /*
            STEP 3:
            REQUIRE FAILURE

            If _amount > 5:
            transaction reverts completely.
        */
        require(
            _amount <= 5,
            "Amount too large"
        );
    }

    /*
    =====================================================
    SAFE EXECUTION
    =====================================================

    Validation first.
    */

    function safeExecution(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATE BEFORE CHANGES
        */
        require(
            _amount <= 5,
            "Amount too large"
        );

        /*
            UPDATE STATE AFTER VALIDATION
        */
        globalCounter =
            globalCounter + _amount;

        balances[msg.sender] =
            balances[msg.sender] + _amount;
    }
}

/*
=========================================================
INITIAL STATE
=========================================================

globalCounter = 0

balances[Alice] = 0

=========================================================
TRACE:
brokenExecution(3)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
0 + 3

TEMP VALUE:
3

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(3 <= 5)

RESULT:
true

---------------------------------------------------------
TRANSACTION SUCCEEDS
---------------------------------------------------------

FINAL STATE:

globalCounter = 3

balances[Alice] = 3

=========================================================
TRACE:
brokenExecution(10)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

globalCounter =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 2
---------------------------------------------------------

balances[Alice] =
3 + 10

TEMP VALUE:
13

---------------------------------------------------------
STEP 3
---------------------------------------------------------

require(10 <= 5)

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

ALL STATE CHANGES UNDONE.

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

globalCounter = 3

balances[Alice] = 3

---------------------------------------------------------

IMPORTANT:
Temporary values disappear.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
brokenExecution(3)

---------------------------------------------------------

STEP 3:
Call:
globalCounter()

EXPECTED:
3

---------------------------------------------------------

STEP 4:
Call:
balances(your_address)

EXPECTED:
3

---------------------------------------------------------

STEP 5:
Call:
brokenExecution(10)

EXPECTED:
Transaction reverts

---------------------------------------------------------

STEP 6:
Call:
globalCounter()

EXPECTED:
Still 3

---------------------------------------------------------

STEP 7:
Call:
balances(your_address)

EXPECTED:
Still 3

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
- entire transaction succeeds

OR:
- entire transaction reverts

=========================================================
WHAT REVERT DOES
=========================================================

When require() fails:

EVM:
- undoes storage writes
- restores old state
- stops execution
- refunds remaining gas

=========================================================
TEMPORARY EXECUTION STATE
=========================================================

During execution:

Temporary storage updates exist internally.

---------------------------------------------------------

BUT:
They persist ONLY if transaction succeeds.

=========================================================
WHY VALIDATION-FIRST MATTERS
=========================================================

BEST PRACTICE:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

This is:
Checks-Effects-Interactions pattern.

=========================================================
BAD PATTERN
=========================================================

1. update storage
2. validate later

---------------------------------------------------------

Problems:
- wasted gas
- dangerous with external calls
- harder to audit

=========================================================
GAS OBSERVATION
=========================================================

Even reverted transactions:
consume gas.

---------------------------------------------------------

Reason:
Computation already executed.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE EXECUTION ORDER
---------------------------------------------------------

Auditors inspect:
what changes BEFORE revert points.

---------------------------------------------------------
2. PARTIAL STATE ASSUMPTIONS
---------------------------------------------------------

Partial updates cannot survive revert.

---------------------------------------------------------
3. EXTERNAL CALL DANGER
---------------------------------------------------------

External interactions before revert
may create reentrancy risks.

---------------------------------------------------------
4. CEI PATTERN
---------------------------------------------------------

Checks -> Effects -> Interactions
improves security.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker repeatedly triggers:
expensive computation + revert.

Result:
gas griefing DOS.

---------------------------------------------------------

ANOTHER RISK

Improper external-call ordering
before revert may expose vulnerabilities.

=========================================================
REAL AUDITOR QUESTIONS
=========================================================

Auditors ask:

- What happens before require()?
- Can external calls occur first?
- What reverts?
- What persists?
- Is rollback behavior understood?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add external token transfer logic
2. Trigger revert after external call
3. Observe rollback behavior carefully

BONUS:
Implement proper CEI ordering.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Ethereum transactions are atomic
- require() failure reverts all state changes
- Temporary updates disappear after revert
- Storage persists only on success
- Validation-first is preferred
- Reverted transactions still consume gas
- CEI pattern improves security
- Execution order matters heavily
- Auditors trace rollback behavior carefully
- Partial state corruption is prevented by EVM atomicity

=========================================================
*/
//Patched code