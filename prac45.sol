// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use modifier after function
CONCEPT: Post-execution flow
=========================================================

OBJECTIVE

- Learn modifier post-execution behavior
- Understand code execution after _;
- Learn execution wrapping flow
- Understand advanced modifier architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Modifiers can execute:
- BEFORE function body
- AFTER function body

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

The special symbol:

_;

represents:
"insert function body here"

---------------------------------------------------------

Code:
BEFORE _;  -> pre-execution
AFTER  _;  -> post-execution

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Post-execution modifiers are used for:

- cleanup logic
- logging
- invariant checks
- reentrancy unlocking
- accounting verification

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Post-execution logic appears in:

- ReentrancyGuard
- fee settlement systems
- invariant validation
- logging frameworks
- protocol accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- hidden post-state mutations
- execution ordering
- invariant enforcement
- modifier side effects
- reentrancy lock release

=========================================================
*/
contract PostExecutionModifierVul {

    bool public locked;

    mapping(address => uint256) public balances;

    modifier noReentrant() {

        require(
            locked == false,
            "Reentrant call blocked"
        );

        locked = true;

        _;

        /*
            VULNERABILITY:

            Developer forgot:
            locked = false;
        */
    }

    function secureDeposit(
        uint256 _amount
    )
        external
        noReentrant
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
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
Modifier executes FIRST.

---------------------------------------------------------

trackExecution()

---------------------------------------------------------

PRE-EXECUTION:

lastAction =
"Function started"

---------------------------------------------------------

STEP 2:
_; reached

Execution enters function body.

---------------------------------------------------------

STEP 3:
Function body executes.

balances[Alice] += 50

---------------------------------------------------------

STEP 4:
Function body finishes.

Execution RETURNS to modifier.

---------------------------------------------------------

STEP 5:
POST-EXECUTION runs.

lastAction =
"Function completed"

---------------------------------------------------------

FINAL STATE:

balances[Alice] = 50

lastAction =
"Function completed"

=========================================================
REENTRANCY MODIFIER TRACE
=========================================================

CALL:
secureDeposit(100)

=========================================================

STEP 1:
Modifier executes.

---------------------------------------------------------

CHECK:
locked == false

RESULT:
true

---------------------------------------------------------

STEP 2:
locked = true

---------------------------------------------------------

STEP 3:
_; reached

Function body executes.

---------------------------------------------------------

STEP 4:
balances[Alice] += 100

---------------------------------------------------------

STEP 5:
Function body finishes.

---------------------------------------------------------

STEP 6:
POST-EXECUTION LOGIC

locked = false

---------------------------------------------------------

FINAL STATE:

locked = false

=========================================================
IMPORTANT EXECUTION MODEL
=========================================================

Modifier wraps function body.

---------------------------------------------------------

FLOW:

modifier start
    ->
function body
    ->
modifier end

=========================================================
VISUAL EXECUTION FLOW
=========================================================

trackExecution()
{
    before logic

    _;

    after logic
}

---------------------------------------------------------

deposit()
is inserted at _;

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
lastAction()

EXPECTED:
"Function completed"

---------------------------------------------------------

STEP 5:
Call:
secureDeposit(100)

---------------------------------------------------------

STEP 6:
Call:
locked()

EXPECTED:
false

---------------------------------------------------------

OBSERVE:
Modifier unlocked AFTER execution.

=========================================================
VERY IMPORTANT SECURITY UNDERSTANDING
=========================================================

Post-execution modifier code
runs ONLY if execution reaches it.

---------------------------------------------------------

If transaction reverts:
post-execution code may NOT execute.

=========================================================
CRITICAL REENTRANCY UNDERSTANDING
=========================================================

noReentrant pattern:

1. lock before execution
2. execute function
3. unlock after execution

---------------------------------------------------------

This protects:
against nested reentrant calls.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. HIDDEN POST-STATE MUTATIONS
---------------------------------------------------------

Modifiers may silently:
change storage AFTER execution.

---------------------------------------------------------
2. LOCK NEVER RELEASED
---------------------------------------------------------

If unlock logic incorrect:
contract may freeze.

---------------------------------------------------------
3. EXECUTION ORDER BUGS
---------------------------------------------------------

Post-execution logic may:
break assumptions.

---------------------------------------------------------
4. MODIFIER SIDE EFFECTS
---------------------------------------------------------

Complex modifiers increase audit difficulty.

=========================================================
GAS OBSERVATION
=========================================================

Post-execution logic:
adds additional gas cost.

---------------------------------------------------------

Complex modifier chains:
increase execution complexity.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- What executes after _; ?
- Can post-logic fail?
- Are locks always released?
- Does modifier mutate state?
- Is execution order safe?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets:
unlock step after execution.

Result:
permanent DOS/frozen contract.

---------------------------------------------------------

ANOTHER RISK

Post-execution modifier
changes state unexpectedly.

Result:
hidden accounting bug.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Pre-modifier logic
2. Function execution
3. Post-modifier logic
4. Revert behavior
5. Lock/unlock guarantees

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add execution counter modifier
2. Increment counter AFTER function
3. Add failed-attempt tracker
4. Add event emission after execution

BONUS:
Build complete custom:
nonReentrant modifier.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Modifiers can execute after function body
- _; represents function insertion point
- Post-execution logic wraps function execution
- Reentrancy guards use post-execution unlock flow
- Modifiers may mutate state after execution
- Execution order matters heavily
- Failed execution may skip post-logic
- Hidden modifier effects increase audit complexity
- Auditors trace modifier wrapping carefully
- Modifier flow is critical for smart contract security

=========================================================
*/
/*
Audit Report

Title: No Security Vulnerability Identified in Modifier Implementation

Severity: Informational

Location:
Contract: PostExecutionModifier

Functions:

* deposit()
* secureDeposit()

Modifiers:

* trackExecution()
* noReentrant()

Description:

The contract correctly implements both pre-execution and post-execution modifier logic.

The trackExecution() modifier updates the lastAction variable before and after function execution as intended.

The noReentrant() modifier correctly:

1. Checks that the contract is not locked
2. Sets locked = true before function execution
3. Executes the protected function
4. Resets locked = false after execution

This follows the standard reentrancy guard pattern.

Impact:

No direct security impact identified.

The contract behaves as expected:

* Unauthorized reentrant calls are blocked
* The lock is released after execution
* State updates occur in the intended order
* Failed transactions revert all state changes

Proof of Verification:

Call:

secureDeposit(100)

Execution:

1. require(locked == false)
2. locked = true
3. function body executes
4. balances[msg.sender] += 100
5. locked = false

Final State:

locked = false

Subsequent calls continue to function normally.

Root Cause Analysis:

No vulnerability identified.

The unlock operation:

locked = false;

is present and correctly executed after the function body.

Security Assessment:

Access Control:
PASS

Modifier Execution Order:
PASS

Post-Execution Logic:
PASS

Lock Release Logic:
PASS

Reentrancy Protection Pattern:
PASS

Recommendation:

No remediation required.

Optional Improvements:

* Replace revert strings with custom errors for gas efficiency.
* Emit events for deposits.
* Consider using OpenZeppelin ReentrancyGuard in production systems.
* Add NatSpec documentation for modifiers.

Conclusion:

The contract correctly demonstrates post-execution modifier behavior and does not contain a security vulnerability related
to modifier execution flow or lock release.
*/

// Patched code
contract PostExecutionModifier {

    bool public locked;

    mapping(address => uint256) public balances;

    modifier noReentrant() {

        require(
            locked == false,
            "Reentrant call blocked"
        );

        locked = true;

        _;

        /*
            FIX:
            Always unlock after execution.
        */
        locked = false;
    }

    function secureDeposit(
        uint256 _amount
    )
        external
        noReentrant
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }
}