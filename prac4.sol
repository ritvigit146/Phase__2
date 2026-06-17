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
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Only owner can update status
    function setStatus(bool _status) public {
        require(msg.sender == owner, "Only owner");
        isActive = _status;
    }

    // Mini Challenge: Toggle current status
    function toggleStatus() public {
        require(msg.sender == owner, "Only owner");
        isActive = !isActive;
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

Title: Missing Access Control in setStatus() and toggleStatus()

Severity: Medium because any external user can modify critical boolean state affecting contract logic

Location:
Contract: StoreBooleanVul
Functions: setStatus(), toggleStatus()

Vulnerability Description:
The contract allows any external user to modify the isActive state variable because no access control mechanism is implemented. 
Both setStatus() and toggleStatus() are declared public without authorization checks.

Impact:
An attacker can arbitrarily change the boolean state, which may control critical protocol behavior such as:

- pausing/unpausing contract operations
- enabling/disabling withdrawals
- bypassing security restrictions
- manipulating system workflow

This can lead to serious protocol malfunction or unauthorized access to restricted functionality.

Proof of Concept:

1. Deploy contract
2. User A calls:
   setStatus(true)
3. Attacker calls:
   toggleStatus()
4. Contract state changes successfully without restriction

Root Cause:
Both functions are declared public and lack any require() statement to verify the caller identity.

Recommendation:
Restrict access to trusted users (e.g., owner) using access control.

Example fix:
require(msg.sender == owner, "Only owner");

OR implement owner-based control:

address public owner;

constructor() {
    owner = msg.sender;
}

function setStatus(bool _status) public {
    require(msg.sender == owner, "Only owner");
    isActive = _status;
}

function toggleStatus() public {
    require(msg.sender == owner, "Only owner");
    isActive = !isActive;
}

Status: Fixed in secured version when access control is added.
*/

//Patched code
contract StoreBoolean {

    bool public isActive;

    function setStatus(bool _status) public {
        isActive = _status;
    }

    // Toggle boolean state
    function toggleStatus() public {
        isActive = !isActive;
    }

    function getStatus() public view returns (bool) {
        return isActive;
    }
}