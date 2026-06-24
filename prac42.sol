// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call internal function
CONCEPT: Internal flow
=========================================================

OBJECTIVE

- Learn how internal functions work
- Understand internal execution flow
- Learn function visibility behavior
- Understand how contracts organize logic internally

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Internal functions:

- can only be called inside contract
- cannot be called externally
- help modularize logic
- reduce code duplication

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Internal calls do NOT create:
external transactions.

Execution stays inside same contract context.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most production contracts heavily use:

- internal helper functions
- internal validation
- internal accounting logic
- reusable internal modules

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Internal functions used in:

- ERC20 transfer logic
- staking calculations
- DeFi accounting
- reward systems
- governance modules
- validation helpers

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- internal call flow
- hidden state mutations
- access assumptions
- recursive risks
- inherited internal logic

=========================================================
*/
contract InternalFunctionFlowVul {

    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    function deposit(uint256 _amount) external {

        _validateAmount(_amount);

        _updateBalance(
            msg.sender,
            _amount
        );

        totalDeposits += _amount;
    }

    function _validateAmount(
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

    function _updateBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] += _amount;
    }

    function _calculateBonus(
        uint256 _amount
    )
        internal
        pure
        returns (uint256)
    {
        return (_amount * 10) / 100;
    }

    /*
        VULNERABLE

        Validation checks only _amount.

        Final credited amount becomes:
        _amount + bonus

        Which may violate intended limits.
    */
    function depositWithBonus(
        uint256 _amount
    )
        external
    {
        _validateAmount(_amount);

        uint256 bonus =
            _calculateBonus(_amount);

        _updateBalance(
            msg.sender,
            _amount + bonus
        );

        totalDeposits +=
            (_amount + bonus);
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
External function executes.

---------------------------------------------------------

deposit(50)

---------------------------------------------------------

STEP 2:
Internal function called:

_validateAmount(50)

---------------------------------------------------------

REQUIRE CHECKS:

50 > 0 -> true

50 <= 100 -> true

---------------------------------------------------------

STEP 3:
Internal function returns.

Execution resumes in deposit().

---------------------------------------------------------

STEP 4:
Internal function called:

_updateBalance(Alice, 50)

---------------------------------------------------------

STORAGE UPDATE:

balances[Alice] += 50

---------------------------------------------------------

STEP 5:
totalDeposits += 50

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

totalDeposits = 50

=========================================================
IMPORTANT INTERNAL FLOW
=========================================================

Execution NEVER leaves contract.

---------------------------------------------------------

NO external call occurs.

---------------------------------------------------------

NO new transaction created.

=========================================================
TRACE:
depositWithBonus(100)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

_validateAmount(100)

Validation passes.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

_calculateBonus(100)

RESULT:
10

---------------------------------------------------------
STEP 3
---------------------------------------------------------

_updateBalance(Alice, 110)

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] += 110

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

OBSERVE:
100 + 10 bonus added

=========================================================
IMPORTANT INTERNAL FUNCTION UNDERSTANDING
=========================================================

internal functions:

- callable only inside contract
- callable by inherited contracts
- invisible externally

=========================================================
INTERNAL VS EXTERNAL
=========================================================

---------------------------------------------------------
INTERNAL
---------------------------------------------------------

- same contract context
- cheaper
- no ABI encoding
- no external call

---------------------------------------------------------
EXTERNAL
---------------------------------------------------------

- callable outside contract
- ABI encoding required
- external transaction possible

=========================================================
WHY INTERNAL FUNCTIONS ARE IMPORTANT
=========================================================

Benefits:

- reusable logic
- cleaner code
- easier auditing
- modular architecture
- reduced duplication

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN STATE CHANGES
---------------------------------------------------------

Internal functions may:
silently modify storage.

---------------------------------------------------------
2. INHERITANCE RISKS
---------------------------------------------------------

Child contracts can access:
internal functions.

---------------------------------------------------------
3. COMPLEX INTERNAL FLOW
---------------------------------------------------------

Deep internal call chains
make auditing harder.

---------------------------------------------------------
4. RECURSION RISK
---------------------------------------------------------

Internal recursive calls
may exhaust gas.

=========================================================
GAS OBSERVATION
=========================================================

Internal calls are:
cheaper than external calls.

---------------------------------------------------------

Reason:
No message call overhead.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which internal functions modify storage?
- Can inherited contracts abuse them?
- Is execution flow clear?
- Are validations centralized?
- Are internal assumptions safe?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Internal validation omitted
in one execution path.

Result:
logic bypass.

---------------------------------------------------------

ANOTHER RISK

Inherited contract overrides logic
unexpectedly.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Internal call chains
2. Storage mutations
3. Validation flow
4. Reusable helper logic
5. Inheritance behavior

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add internal withdraw helper
2. Add internal fee calculation
3. Add admin-only internal modifier logic

BONUS:
Create inherited child contract
using internal functions.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Internal functions stay inside contract
- Internal calls are cheaper than external calls
- Internal functions organize reusable logic
- Internal execution keeps same context
- Internal functions can modify storage
- Inherited contracts can access internal functions
- Auditors trace internal call chains carefully
- Modular architecture improves maintainability
- Hidden internal logic may create vulnerabilities
- Internal flow understanding is critical for auditing

=========================================================
*/
/*
Audit Report

Title: Inconsistent Validation in depositWithBonus()

Severity: Medium

Location:
Contract: InternalFunctionFlow
Function: depositWithBonus()

Vulnerability Description:

The depositWithBonus() function validates only the
original _amount parameter through the internal
_validateAmount() function.

However, after validation, the contract calculates
a bonus and credits:

```
_amount + bonus
```

to the user's balance.

As a result, the final credited amount may exceed
the maximum value enforced by validation logic.

This creates inconsistent business-rule enforcement
between validated input and actual state updates.

Impact:

A user can receive a balance increase larger than
the protocol's intended maximum deposit amount.

If deposit limits are security-critical or used for:

* reward calculations
* governance power
* staking limits
* protocol accounting

then users may gain unintended advantages.

Proof of Concept:

1. Deploy contract

2. User calls:

   depositWithBonus(100)

3. Internal validation executes:

   _validateAmount(100)

4. Validation passes because:

   100 <= 100

5. Bonus calculated:

   bonus = 10

6. User credited:

   100 + 10 = 110

7. Final credited amount exceeds the validated limit.

Root Cause:

Validation occurs before bonus calculation.

The contract validates only the user-provided input
and fails to validate the final amount written to
storage.

Recommendation:

Validate the final credited amount before updating
balances.

Example:

```
uint256 bonus =
    _calculateBonus(_amount);

uint256 finalAmount =
    _amount + bonus;

require(
    finalAmount <= 100,
    "Amount too large"
);

_updateBalance(
    msg.sender,
    finalAmount
);
```

Ensure all internal execution paths enforce the
same business rules and limits.

*/
//Patched code
contract InternalFunctionFlow {

    error InvalidAmount();
    error AmountTooLarge();

    mapping(address => uint256) public balances;

    uint256 public totalDeposits;

    uint256 public constant MAX_CREDIT = 100;

    function deposit(
        uint256 _amount
    )
        external
    {
        _validateAmount(_amount);

        _updateBalance(
            msg.sender,
            _amount
        );

        totalDeposits += _amount;
    }

    function _validateAmount(
        uint256 _amount
    )
        internal
        pure
    {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        if (_amount > 100) {
            revert AmountTooLarge();
        }
    }

    function _updateBalance(
        address _user,
        uint256 _amount
    )
        internal
    {
        balances[_user] += _amount;
    }

    function _calculateBonus(
        uint256 _amount
    )
        internal
        pure
        returns (uint256)
    {
        return (_amount * 10) / 100;
    }

    function depositWithBonus(
        uint256 _amount
    )
        external
    {
        _validateAmount(_amount);

        uint256 bonus =
            _calculateBonus(_amount);

        uint256 finalAmount =
            _amount + bonus;

        /*
            Validate final credited value.
        */
        if (
            finalAmount > MAX_CREDIT
        ) {
            revert AmountTooLarge();
        }

        _updateBalance(
            msg.sender,
            finalAmount
        );

        totalDeposits += finalAmount;
    }
}