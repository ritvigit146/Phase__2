// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Execute function line-by-line manually
CONCEPT: Mental execution tracing
=========================================================

OBJECTIVE

- Learn how to mentally execute Solidity code
- Understand EVM execution flow
- Learn state changes step-by-step
- Build auditor-style tracing skills

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Professional auditors mentally trace:

- every variable change
- every storage update
- every require()
- every loop iteration
- every external call

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Auditing is NOT only reading syntax.

You must simulate execution in your head.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most vulnerabilities are found by:

- tracing state changes
- understanding execution order
- detecting unexpected behavior

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Mental execution tracing is critical for:

- smart contract auditing
- exploit analysis
- protocol reviews
- gas optimization
- invariant checking

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors mentally track:

- msg.sender
- msg.value
- storage changes
- memory usage
- require conditions
- external interactions
- reentrancy possibilities

=========================================================
*/
contract MentalExecutionTracingVul {

    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    function deposit(
        uint256 _amount
    )
        external
    {
        balances[msg.sender] += _amount;
        totalBalance += _amount;
    }

    /*
        VULNERABLE
        Missing balance validation
    */
    function withdraw(
        uint256 _amount
    )
        external
    {
        balances[msg.sender] =
            balances[msg.sender] - _amount;

        totalBalance =
            totalBalance - _amount;
    }
}

/*
=========================================================
MANUAL EXECUTION TRACE
=========================================================

---------------------------------------------------------
INITIAL STATE
---------------------------------------------------------

totalBalance = 0

balances[Alice] = 0

=========================================================
TRACE:
deposit(100)
called by Alice
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(_amount > 0)

CHECK:
100 > 0

RESULT:
true

Execution continues.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

currentBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 0

SO:

currentBalance = 0

---------------------------------------------------------
STEP 3
---------------------------------------------------------

newBalance =
currentBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = newBalance

STORAGE UPDATE:

balances[Alice] = 100

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
totalBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 100

totalBalance = 100

=========================================================
SECOND TRACE
=========================================================

CALL:
withdraw(40)

by Alice

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 100

---------------------------------------------------------
STEP 2
---------------------------------------------------------

require(userBalance >= _amount)

CHECK:
100 >= 40

RESULT:
true

---------------------------------------------------------
STEP 3
---------------------------------------------------------

updatedBalance =
100 - 40

= 60

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = 60

STORAGE UPDATED

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
100 - 40

= 60

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 60

totalBalance = 60

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
totalBalance()

EXPECTED:
100

---------------------------------------------------------

STEP 5:
Call:
withdraw(40)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
60

---------------------------------------------------------

STEP 7:
Call:
totalBalance()

EXPECTED:
60

=========================================================
FAILURE TRACE
=========================================================

CALL:
withdraw(1000)

WHEN:
balance = 60

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance = 60

---------------------------------------------------------
STEP 2
---------------------------------------------------------

CHECK:
60 >= 1000

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

NO STATE CHANGES OCCUR.

=========================================================
IMPORTANT AUDITOR SKILL
=========================================================

WHILE TRACING:

Track:

- storage reads
- storage writes
- memory variables
- require conditions
- execution order
- state before/after

=========================================================
WHY EXECUTION ORDER MATTERS
=========================================================

Incorrect order may cause:

- reentrancy
- stale state
- accounting bugs
- invariant violations

=========================================================
MENTAL MODEL USED BY AUDITORS
=========================================================

FOR EVERY LINE ASK:

1. What data is read?
2. From storage/memory/calldata?
3. What changes?
4. Can execution revert?
5. What happens if attacker controls input?
6. What is final state?

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE STATE CAREFULLY
---------------------------------------------------------

Most bugs hide in:
state transitions.

---------------------------------------------------------
2. WATCH STORAGE WRITES
---------------------------------------------------------

Storage changes are critical.

---------------------------------------------------------
3. CHECK REQUIRE ORDER
---------------------------------------------------------

Validation must happen before:
dangerous operations.

---------------------------------------------------------
4. THINK LIKE ATTACKER
---------------------------------------------------------

Ask:
"What if input is malicious?"

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

If require() were missing:

Attacker could:
withdraw more than balance.

---------------------------------------------------------

ANOTHER RISK

Incorrect execution order may:
enable reentrancy exploits.

=========================================================
MINI CHALLENGE
=========================================================

Manually trace:

1. deposit(500)
2. withdraw(200)
3. deposit(50)

Write:
- every variable value
- every storage update
- final contract state

BONUS:
Add transfer() function
and trace sender + receiver balances.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Auditors mentally execute code
- Storage changes must be tracked carefully
- require() controls execution flow
- Reverts undo state changes
- Execution order matters heavily
- State tracing reveals vulnerabilities
- External input is attacker-controlled
- Storage/memory/calldata differ greatly
- Manual tracing is essential for auditing
- Professional auditors simulate EVM execution mentally

=========================================================
*/
/*
Audit Report

Title: Missing Input Validation in deposit()

Severity: Low

Location:
Contract: MentalExecutionTracing
Function: deposit()

Vulnerability Description:

The deposit() function does not validate the _amount
parameter before updating user balances and totalBalance.

As a result, users can call:

    deposit(0)

which performs unnecessary execution and storage writes
without representing a meaningful deposit operation.

The function accepts invalid business-logic input.

Impact:

Currently:

- No direct fund loss occurs
- No unauthorized access occurs
- Contract accounting remains correct

However:

- Invalid deposits are accepted
- Protocol rules are not enforced
- Unnecessary transactions consume gas
- Future integrations may assume deposits are always
  greater than zero

Proof of Concept:

1. Deploy contract

2. Call:

    deposit(0)

3. Transaction succeeds

4. Storage values remain:

    balances[user] = 0
    totalBalance = 0

5. Invalid operation was accepted

Root Cause:

The deposit() function lacks validation for the
_amount parameter.

No require() statement exists to ensure:

    _amount > 0

before processing.

Recommendation:

Validate input before updating state.

Example:

    require(
        _amount > 0,
        "Invalid amount"
    );

    balances[msg.sender] += _amount;
    totalBalance += _amount;

Validation should occur before any state changes
following the Checks-Effects-Interactions pattern
*/

//Patched code
contract MentalExecutionTracing {

    error InsufficientBalance();
    error InvalidAmount();

    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    function deposit(
        uint256 _amount
    )
        external
    {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        balances[msg.sender] += _amount;

        totalBalance += _amount;
    }

    function withdraw(
        uint256 _amount
    )
        external
    {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        if (
            balances[msg.sender] < _amount
        ) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= _amount;

        totalBalance -= _amount;
    }
}