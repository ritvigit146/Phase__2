// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return early from function
CONCEPT: Execution stopping
=========================================================

OBJECTIVE

- Learn how early return works
- Understand execution stopping behavior
- Learn control-flow optimization
- Understand auditor-style execution tracing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

return immediately stops:
- function execution
- remaining code execution
- further state changes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Once return executes:

Everything after it is skipped.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Early return is heavily used for:

- validation
- optimization
- branch control
- error handling
- gas reduction

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Used in:

- ERC20 logic
- DeFi routers
- staking systems
- access control
- governance systems
- liquidation checks

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- skipped code paths
- unreachable logic
- missed state updates
- incorrect return placement
- authorization bypasses

=========================================================
*/
contract EarlyReturnVulnerable {
    mapping(address => uint256) public balances;

    bool public paused;

    function setPaused(bool _status) external {
        // VULNERABLE
        // Anyone can change protocol state
        paused = _status;
    }

    function deposit(uint256 _amount) external {
        if (paused) {
            return;
        }

        if (_amount == 0) {
            return;
        }

        balances[msg.sender] += _amount;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

paused = false

balances[Alice] = 0

=========================================================
TRACE:
deposit(10)
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

if (paused == true)

CHECK:
false == true

RESULT:
false

Execution continues.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

if (_amount == 0)

CHECK:
10 == 0

RESULT:
false

Execution continues.

---------------------------------------------------------
STEP 3
---------------------------------------------------------

balances[Alice] += 10

FINAL STATE:

balances[Alice] = 10

=========================================================
EARLY RETURN TRACE
=========================================================

SET:
paused = true

---------------------------------------------------------

CALL:
deposit(10)

---------------------------------------------------------
STEP 1
---------------------------------------------------------

if (paused == true)

CHECK:
true == true

RESULT:
true

---------------------------------------------------------

RETURN EXECUTES

---------------------------------------------------------

FUNCTION STOPS IMMEDIATELY

---------------------------------------------------------

STEP 2 and STEP 3 NEVER EXECUTE

---------------------------------------------------------

FINAL STATE:

balances[Alice] unchanged

=========================================================
ANOTHER TRACE
=========================================================

CALL:
checkLevel(95)

---------------------------------------------------------

FIRST IF:
95 >= 90

RESULT:
true

---------------------------------------------------------

RETURN "Elite"

---------------------------------------------------------

FUNCTION ENDS IMMEDIATELY

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(10)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
setPaused(true)

---------------------------------------------------------

STEP 5:
Call:
deposit(50)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
Still 10

---------------------------------------------------------

OBSERVE:
Function returned early.

---------------------------------------------------------

STEP 7:
Call:
checkLevel(95)

EXPECTED:
"Elite"

---------------------------------------------------------

STEP 8:
Call:
checkLevel(60)

EXPECTED:
"Standard"

---------------------------------------------------------

STEP 9:
Call:
checkLevel(20)

EXPECTED:
"Rejected"

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

return does TWO things:

1. optionally returns value
2. STOPS execution immediately

=========================================================
VERY IMPORTANT
=========================================================

Any code AFTER return:
is unreachable.

---------------------------------------------------------

Unreachable code:
never executes.

=========================================================
EARLY RETURN VS REQUIRE
=========================================================

---------------------------------------------------------
EARLY RETURN
---------------------------------------------------------

- Stops execution silently
- No revert
- State before return persists

---------------------------------------------------------
REQUIRE
---------------------------------------------------------

- Reverts transaction
- Undoes state changes
- Throws error

=========================================================
WHEN EARLY RETURN IS USEFUL
=========================================================

GOOD FOR:

- optional execution
- gas optimization
- branch exits
- skip logic
- read-only checks

=========================================================
WHEN REQUIRE IS BETTER
=========================================================

GOOD FOR:

- validation
- security rules
- invariant enforcement
- authorization

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. SKIPPED SECURITY CHECKS
---------------------------------------------------------

Early return may bypass logic accidentally.

---------------------------------------------------------
2. UNREACHABLE CODE
---------------------------------------------------------

Dead code increases confusion.

---------------------------------------------------------
3. PARTIAL EXECUTION
---------------------------------------------------------

Some state may update
before early return.

---------------------------------------------------------
4. LOGIC FRAGMENTATION
---------------------------------------------------------

Too many returns make auditing harder.

=========================================================
GAS OBSERVATION
=========================================================

Early return:
can reduce gas usage.

---------------------------------------------------------

Reason:
remaining code skipped.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which paths return early?
- What code becomes unreachable?
- Are security checks skipped?
- Can attacker abuse branch exits?
- Does state remain consistent?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer places return incorrectly.

Critical validation skipped.

Result:
authorization bypass.

---------------------------------------------------------

ANOTHER RISK

Partial state update before return
may break invariants.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every return point
2. Remaining skipped logic
3. State before return
4. State after return
5. Reachable vs unreachable code

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist logic
2. Return early for blacklisted users
3. Add require() version too
4. Compare behavior carefully

BONUS:
Create function with:
multiple nested early returns.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- return stops execution immediately
- Remaining code becomes unreachable
- Early return does NOT revert transaction
- require() and return behave differently
- Early returns can optimize gas
- Incorrect returns may skip security checks
- Auditors trace all execution exits
- Branch analysis is critical
- Partial execution must be understood
- Control flow impacts security heavily

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in setPaused()

Severity: Medium because unauthorized users can modify the paused state
and disrupt normal contract functionality.

Location:
Contract: EarlyReturnExample
Function: setPaused()

Vulnerability Description:

The setPaused() function allows any external user to modify
the paused state variable because no access control mechanism
is implemented.

As a result, an attacker can arbitrarily pause or unpause
the contract.

Since deposit() immediately returns when paused == true,
an attacker can prevent users from successfully depositing.

Impact:

An attacker can trigger a denial-of-service condition
against deposit functionality.

If this pause mechanism controlled critical protocol logic such as:

- deposits
- withdrawals
- staking
- token transfers

then unauthorized users could disrupt normal protocol operations.

Proof of Concept:

                1. Deploy contract

                2. User A calls:
                    deposit(100)

                3. Attacker calls:
                    setPaused(true)

                4. User A calls:
                    deposit(50)

                5. Function returns early

                6. balances[UserA] remains unchanged

                7. Deposits are effectively disabled

Root Cause:

The function is declared external without any authorization checks.

No require() statement validates the caller identity before
modifying the paused state.

Recommendation:

Restrict access using an owner check.

Example:

                address public owner;

                constructor() {
                    owner = msg.sender;
                }

                function setPaused(bool _status) external {
                    require(
                        msg.sender == owner,
                        "Not owner"
                    );

                    paused = _status;
                }

*/

//Patched code
contract EarlyReturnPatched {
    mapping(address => uint256) public balances;

    bool public paused;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setPaused(bool _status) external {
        require(
            msg.sender == owner,
            "Not owner"
        );

        paused = _status;
    }

    function deposit(uint256 _amount) external {
        require(
            !paused,
            "Contract paused"
        );

        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }
}