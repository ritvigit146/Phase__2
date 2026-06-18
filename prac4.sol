// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store bool in state
CONCEPT: Boolean storage
=========================================================

OBJECTIVE

- Learn how Solidity stores boolean values
- Understand true/false state handling
- Learn how bool variables control contract logic
- Understand security implications of boolean flags

---------------------------------------------------------
WHAT IS A BOOLEAN?
---------------------------------------------------------

Boolean values can only be:

- true
- false

Solidity type:
bool

---------------------------------------------------------
COMMON REAL-WORLD USES
---------------------------------------------------------

Boolean variables are heavily used for:

- pause/unpause systems
- access permissions
- voting status
- transaction execution tracking
- reentrancy locks
- feature enable/disable switches

---------------------------------------------------------
IMPORTANT CONCEPT
---------------------------------------------------------

State bool variables are stored permanently
inside blockchain storage.

Their values persist across transactions.

---------------------------------------------------------
DEFAULT VALUE
---------------------------------------------------------

bool default value = false

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Who can change boolean flags?
- Can attackers bypass restrictions?
- Is pause mechanism secure?
- Can critical flags be manipulated?
- Are flags reset correctly?

=========================================================
*/
contract StoreBooleanVul {

    bool public isActive;

    function setStatus(bool _status) public {
        isActive = _status;
    }

    function getStatus() public view returns (bool) {
        return isActive;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

isActive = false

Reason:
Default bool value is false.

---------------------------------------------------------

CALL:
setStatus(true)

EVM ACTIONS:

1. Transaction reaches contract
2. Boolean value arrives through calldata
3. Storage slot updated
4. isActive becomes true
5. Gas consumed

---------------------------------------------------------

CALL:
setStatus(false)

RESULT:
Storage updated again

isActive becomes false

Old value overwritten.

---------------------------------------------------------

CALL:
getStatus()

EVM reads storage value
and returns current boolean state.

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

EXPECTED:
isActive() => false

---------------------------------------------------------

STEP 2:
Call:
setStatus(true)

EXPECTED:
isActive() => true

---------------------------------------------------------

STEP 3:
Call:
setStatus(false)

EXPECTED:
isActive() => false

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Repeated toggling

Call:
setStatus(true)
setStatus(false)
setStatus(true)

EXPECTED:
Latest value stored successfully

---------------------------------------------------------

OBSERVE:
Boolean state changes permanently
after each transaction.

=========================================================
STORAGE OBSERVATION
=========================================================

Storage example:

Initial:
slot0 => false

After:
setStatus(true)

slot0 => true

After:
setStatus(false)

slot0 => false

Only latest value exists in storage.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

IMPORTANT SECURITY FACT

Boolean flags often control CRITICAL LOGIC.

Example uses:
- contract paused?
- user verified?
- transaction executed?
- admin approved?
- reentrancy locked?

---------------------------------------------------------
1. MISSING ACCESS CONTROL
---------------------------------------------------------

Current issue:
ANYONE can change status.

Real-world danger:
Attacker may:
- pause protocol
- unpause protocol
- bypass protections
- manipulate system behavior

---------------------------------------------------------
2. BOOLEAN MISUSE
---------------------------------------------------------

Incorrect boolean handling can cause:
- stuck funds
- bypassed validations
- repeated execution
- double spending

---------------------------------------------------------
3. STATE DESYNCHRONIZATION
---------------------------------------------------------

Auditors verify:
- flags updated correctly
- flags reset properly
- logic cannot become inconsistent

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose:

isActive controls withdrawals.

Logic:
- true => withdrawals allowed
- false => withdrawals blocked

Attacker calls:

setStatus(true)

Impact:
Restricted functionality becomes enabled.

---------------------------------------------------------

ANOTHER REAL-WORLD ISSUE

Reentrancy guards use booleans.

If boolean reset fails:
- contract may lock forever
OR
- reentrancy protection may fail

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add toggleStatus() function
2. Function should reverse current state

Example:
true -> false
false -> true

HINT:

Use:
isActive = !isActive;

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- bool stores true/false values
- Default bool value is false
- Boolean state persists on blockchain
- Storage updates overwrite old values
- Boolean flags often control critical logic
- Access control is essential
- Incorrect flag handling causes vulnerabilities
- Reentrancy guards commonly use booleans

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in setStatus()

Severity: Medium

Location:
Contract: StoreBooleanVul
Function: setStatus()

Vulnerability Description

The setStatus() function allows any external user to modify the isActive state variable because no access control mechanism is implemented.

Boolean variables are commonly used to control critical protocol functionality such as:

pause/unpause mechanisms
access permissions
withdrawal status
transaction execution tracking
security controls

Because the function is publicly accessible, unauthorized users can manipulate the contract state.

Impact

An attacker can arbitrarily change the value of isActive.

If the boolean flag controls critical protocol logic, this may:

enable restricted functionality
disable protocol operations
bypass intended restrictions
interfere with normal system behavior

For example, if isActive controls withdrawals:

true → withdrawals allowed
false → withdrawals blocked

An attacker could enable or disable withdrawals at will.

Proof of Concept
Deploy contract.

Initial state:

isActive = false
Attacker calls:
setStatus(true);
Transaction succeeds.
Contract state becomes:
isActive = true
Attacker can continue modifying the state:
setStatus(false);
setStatus(true);

No authorization is required.

Root Cause

The function is declared public without any authorization checks.

function setStatus(bool _status) public {
    isActive = _status;
}

No validation is performed to ensure that only trusted users can modify the boolean state.

Recommendation

Implement access control so that only authorized users can modify the status.
*/
//Patched code
contract StoreBoolean {

    bool public isActive;

    function setStatus(bool _status) public {
        isActive = _status;
    }

    function toggleStatus() public {
        isActive = !isActive;
    }

    function getStatus() public view returns (bool) {
        return isActive;
    }
}