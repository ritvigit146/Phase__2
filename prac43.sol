// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call function from function
CONCEPT: Execution chaining
=========================================================

OBJECTIVE

- Learn how one function calls another
- Understand execution chaining
- Learn execution stack flow
- Understand chained state updates

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Functions can call:
other functions.

This creates:
execution chains.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Execution flows step-by-step:

Function A
   ->
Function B
   ->
Function C

Then returns backward.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most smart contracts use:
multi-function execution flow.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Execution chaining used in:

- ERC20 transfers
- DeFi swaps
- staking systems
- lending protocols
- liquidation systems
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution order
- hidden state updates
- reentrancy risk
- recursive loops
- validation propagation

=========================================================
*/
contract FunctionExecutionChainingVul {

    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    function deposit(
        uint256 _amount
    )
        external
    {
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

    /*
        VULNERABLE PATH

        Missing validation.
    */
    function depositWithBonus(
        uint256 _amount
    )
        external
    {
        depositInternal(_amount);

        addBalance(
            msg.sender,
            10
        );
    }

    /*
        Validation accidentally omitted.
    */
    function depositInternal(
        uint256 _amount
    )
        internal
    {
        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

    function validateAmount(
        uint256 _amount
    )
        internal
        pure
    {
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );
    }

    function addBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] += _amount;
    }

    function updateTotal(
        uint256 _amount
    )
        internal
    {
        totalDeposits += _amount;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
deposit() executes.

---------------------------------------------------------

STEP 2:
deposit() calls:

validateAmount(50)

---------------------------------------------------------

VALIDATION PASSES

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 3:
deposit() calls:

addBalance(Alice, 50)

---------------------------------------------------------

STORAGE UPDATE:

balances[Alice] += 50

---------------------------------------------------------

CONTROL RETURNS TO:
deposit()

---------------------------------------------------------

STEP 4:
deposit() calls:

updateTotal(50)

---------------------------------------------------------

STORAGE UPDATE:

totalDeposits += 50

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

totalDeposits = 50

=========================================================
CHAINED FLOW TRACE
=========================================================

CALL:
depositWithBonus(100)

=========================================================

STEP 1:
depositWithBonus() executes.

---------------------------------------------------------

STEP 2:
Calls:

depositInternal(100)

---------------------------------------------------------

depositInternal() calls:

validateAmount(100)

---------------------------------------------------------

Validation passes.

---------------------------------------------------------

depositInternal() calls:

addBalance(Alice, 100)

---------------------------------------------------------

depositInternal() calls:

updateTotal(100)

---------------------------------------------------------

depositInternal() finishes.

---------------------------------------------------------

CONTROL RETURNS TO:
depositWithBonus()

---------------------------------------------------------

STEP 3:
Bonus added:

addBalance(Alice, 10)

---------------------------------------------------------

FINAL STATE:

balances[Alice] += 110

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Function execution behaves like:
STACK FLOW.

---------------------------------------------------------

Execution enters:
called function

Then returns:
to caller function.

=========================================================
VISUAL FLOW
=========================================================

depositWithBonus()
    |
    +--> depositInternal()
             |
             +--> validateAmount()
             |
             +--> addBalance()
             |
             +--> updateTotal()

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(50)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
50

---------------------------------------------------------

STEP 4:
Call:
totalDeposits()

EXPECTED:
50

---------------------------------------------------------

STEP 5:
Call:
depositWithBonus(100)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
160

---------------------------------------------------------

STEP 7:
Call:
totalDeposits()

EXPECTED:
150

=========================================================
IMPORTANT FUNCTION CHAINING UNDERSTANDING
=========================================================

Functions may:
- validate
- compute
- mutate state
- call helper functions

---------------------------------------------------------

Execution order matters heavily.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN STATE MUTATIONS
---------------------------------------------------------

Called functions may:
modify storage unexpectedly.

---------------------------------------------------------
2. VALIDATION GAPS
---------------------------------------------------------

One chain path may skip validation.

---------------------------------------------------------
3. RECURSION RISK
---------------------------------------------------------

Functions calling each other recursively
may exhaust gas.

---------------------------------------------------------
4. EXECUTION ORDER BUGS
---------------------------------------------------------

Incorrect call ordering
may break invariants.

=========================================================
GAS OBSERVATION
=========================================================

More chained calls:
More gas usage.

---------------------------------------------------------

Deep chains:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which functions call others?
- What state changes occur?
- Is validation always enforced?
- Can attacker influence flow?
- Are external calls involved?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets validation
in one chain path.

Attacker uses unsafe path.

---------------------------------------------------------

ANOTHER RISK

External call inside chain
may enable reentrancy.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Call hierarchy
2. Execution order
3. State mutations
4. Validation propagation
5. Revert behavior

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw chain
2. Add fee deduction function
3. Add blacklist validation function
4. Trace full execution manually

BONUS:
Create recursive function
and observe gas behavior.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Functions can call other functions
- Execution follows stack-like flow
- Called function returns control to caller
- Function chains organize logic
- Hidden state mutations may occur
- Validation must propagate through chains
- Execution order matters heavily
- Recursive calls can be dangerous
- Auditors trace full call hierarchy
- Function chaining is core Solidity architecture

=========================================================
*/
/*
Audit Report

Title: Missing Centralized Validation in Execution Chain

Severity: Medium because future execution paths may bypass critical validation checks and violate protocol rules.

Location:
Contract: FunctionExecutionChaining
Function: depositWithBonus()
Function: depositInternal()

Vulnerability Description:

The contract relies on validation being manually called before state-changing
operations.

Currently, depositInternal() performs validation correctly through:

    validateAmount(_amount);

However, the architecture separates validation logic from storage-update logic.

Future developers may create new execution paths that call:

    addBalance()
    updateTotal()

without first calling validateAmount().

This can lead to inconsistent validation enforcement across different
execution chains.

Impact:

An attacker may exploit an alternative execution path to:

- bypass deposit limits
- violate protocol rules
- manipulate accounting values
- create inconsistent system state

If deposit limits are security-critical, this could result in unauthorized
state modifications.

Proof of Concept:

1. Developer creates a new function:

    function emergencyDeposit(uint256 amount) external {
        addBalance(msg.sender, amount);
        updateTotal(amount);
    }

2. Function forgets to call:

    validateAmount(amount);

3. Attacker calls:

    emergencyDeposit(1000000);

4. Deposit limit of 100 is bypassed.

5. Contract accounting becomes inconsistent with intended business rules.

Root Cause:

Validation logic is separated from state-changing logic.

The contract depends on developers remembering to call:

    validateAmount()

before every balance modification.

This assumption may fail as the codebase grows.

Recommendation:

Centralize validation inside the core state-changing function.

Example:

    function depositInternal(
        uint256 _amount
    )
        internal
    {
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

This guarantees all execution paths enforce validation before modifying state.
*/

// Patched code
contract FunctionExecutionChainingPatched {

    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    uint256 public constant BONUS = 10;

    function deposit(
        uint256 _amount
    )
        external
    {
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

    function validateAmount(
        uint256 _amount
    )
        internal
        pure
    {
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );
    }

    function addBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] += _amount;
    }

    function updateTotal(
        uint256 _amount
    )
        internal
    {
        totalDeposits += _amount;
    }

    function depositInternal(
        uint256 _amount
    )
        internal
    {
        validateAmount(_amount);

        addBalance(
            msg.sender,
            _amount
        );

        updateTotal(_amount);
    }

    /*
        PATCHED
        Bonus accounted globally.
    */
    function depositWithBonus(
        uint256 _amount
    )
        external
    {
        depositInternal(_amount);

        addBalance(
            msg.sender,
            BONUS
        );

        updateTotal(BONUS);
    }
}