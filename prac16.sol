// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create local uint variable
CONCEPT: Temporary execution memory
=========================================================

OBJECTIVE

- Learn how local variables work in Solidity
- Understand temporary execution memory
- Learn difference between local variables and storage
- Understand variable lifetime during execution

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Local variables exist ONLY during
function execution.

After function completes:
local variables disappear.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Local variables are NOT stored permanently
on blockchain storage.

They usually live in:
- stack
- memory

---------------------------------------------------------
STATE VARIABLE VS LOCAL VARIABLE
---------------------------------------------------------

STATE VARIABLE:
- stored permanently
- lives in storage
- persists across transactions

LOCAL VARIABLE:
- temporary
- exists only during execution
- disappears after function ends

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Local variables are used for:

- calculations
- temporary values
- loop counters
- intermediate logic
- gas optimization

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is temporary data handled correctly?
- Is storage used unnecessarily?
- Are local variables initialized?
- Can uninitialized variables cause bugs?
- Is memory usage efficient?

=========================================================
*/
contract LocalUintVariableVul {

    uint256 public storedValue;

    // Vulnerable: unnecessary storage write + unsafe logic flow
    function calculateSum(uint256 _a, uint256 _b)
        public
        returns (uint256)
    {
        uint256 sum; // uninitialized local variable (bad practice)

        sum = _a + _b;

        // unnecessary state mutation (should be view/pure)
        storedValue = sum;

        return sum;
    }

    // Vulnerable: conditional assignment leaves stale/default value risk
    function unsafeLogic(uint256 _x, uint256 _y)
        public
    {
        uint256 temp; // uninitialized local variable

        if (_x > 10) {
            temp = _x + _y;
        }

        // if _x <= 10 → temp = 0 (silent wrong state write)
        storedValue = temp;
    }

    // misleading function name (looks safe but can mutate state)
    function demonstrateLocalVariable()
        public
        returns (uint256)
    {
        uint256 temp = 100;

        temp = temp + 50;

        // unnecessary storage dependency risk pattern
        storedValue = temp;

        return temp;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
calculateSum(10, 20)

EVM ACTIONS:

1. _a and _b arrive through calldata
2. Local variable sum created
3. Addition performed
4. sum temporarily stores result
5. Result returned
6. sum destroyed after execution

---------------------------------------------------------

IMPORTANT

sum does NOT persist on blockchain.

---------------------------------------------------------

CALL:
storeCalculatedValue(5, 7)

EVM ACTIONS:

1. Local variable result created
2. result = 12
3. storedValue updated in storage
4. result destroyed after execution
5. storedValue persists permanently

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
calculateSum(10,20)

EXPECTED:
30

---------------------------------------------------------

STEP 3:
Call:
storedValue()

EXPECTED:
0

OBSERVE:
calculateSum did NOT modify storage.

---------------------------------------------------------

STEP 4:
Call:
storeCalculatedValue(5,7)

---------------------------------------------------------

STEP 5:
Call:
storedValue()

EXPECTED:
12

---------------------------------------------------------

STEP 6:
Call:
demonstrateLocalVariable()

EXPECTED:
150

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Use zero values

calculateSum(0,0)

EXPECTED:
0

---------------------------------------------------------

TEST:
Use large uint256 values

EXPECTED:
Solidity ^0.8.x prevents overflow

---------------------------------------------------------

TEST:
Call functions repeatedly

OBSERVE:
Local variables recreated every execution.

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

LOCAL VARIABLES ARE TEMPORARY

They exist only during:
single function execution.

---------------------------------------------------------

AFTER FUNCTION ENDS

Local variables are destroyed.

---------------------------------------------------------

VERY IMPORTANT

This does NOT persist:

uint256 temp = 100;

---------------------------------------------------------

THIS PERSISTS:

storedValue = 100;

because storage is modified.

=========================================================
STACK VS STORAGE
=========================================================

LOCAL UINT VARIABLES

Usually stored in:
EVM stack

---------------------------------------------------------

STATE VARIABLES

Stored in:
blockchain storage

---------------------------------------------------------

STACK:
- temporary
- cheap
- fast

STORAGE:
- permanent
- expensive
- persistent

=========================================================
GAS OBSERVATION
=========================================================

LOCAL VARIABLES:
Cheap

---------------------------------------------------------

STORAGE WRITES:
Expensive

---------------------------------------------------------

Reason:
Storage modifies blockchain state permanently.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNINITIALIZED VARIABLES
---------------------------------------------------------

Auditors verify:
all local variables initialized properly.

---------------------------------------------------------
2. STORAGE MISUSE
---------------------------------------------------------

Developers sometimes use storage
when temporary variable sufficient.

This wastes gas.

---------------------------------------------------------
3. OVERFLOW RISKS
---------------------------------------------------------

Math on local variables still matters.

Solidity ^0.8.x checks overflow automatically.

---------------------------------------------------------
4. TEMPORARY LOGIC VALIDATION
---------------------------------------------------------

Auditors inspect:
- intermediate calculations
- temporary computation correctness
- execution flow consistency

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Incorrect temporary calculations may:
- manipulate balances
- break reward logic
- corrupt protocol state

---------------------------------------------------------

ANOTHER RISK

Developer may incorrectly assume:
local variable persists after execution.

This creates logic bugs.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create local multiplication variable
2. Return multiplication result
3. Do NOT modify storage

BONUS:
Compare gas between:
- local calculation
- storage write

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Local variables are temporary
- Local variables do not persist
- State variables use storage
- Local uint variables usually use stack
- Storage writes consume more gas
- Local variables disappear after execution
- Temporary variables useful for calculations
- view/pure functions avoid storage modification
- Solidity ^0.8.x protects from overflow
- Auditors inspect temporary logic carefully

=========================================================
*/
/*
Audit Report

Contract: LocalUintVariable

Audit Result: Partially Fixed

=========================================================
Finding #1: Unnecessary Storage Write in Calculation
=========================================================

Severity: Low

Status: Fixed

Location:
calculateSum()

Description:

In the vulnerable version, calculateSum()
performed a simple calculation but also wrote
the result to storage.

This caused unnecessary gas consumption and
state modification.

Vulnerable Code:

storedValue = sum;

Impact:

- Increased gas costs
- Unnecessary state changes
- Function could not be marked pure

Remediation:

The function now performs local computation only
and is declared pure.

Patched Code:

function calculateSum(uint256 _a, uint256 _b)
    public
    pure
    returns (uint256)
{
    uint256 sum = _a + _b;
    return sum;
}

Result:

Issue successfully fixed.

=========================================================
Finding #2: Unsafe Local Variable Logic
=========================================================

Severity: Low

Status: Fixed

Location:
safeLogic()

Description:

The vulnerable version used a local variable that
could remain at its default value when certain
conditions were not met.

This could result in unintended storage updates.

Vulnerable Flow:

if (_x > 10) {
    temp = _x + _y;
}

storedValue = temp;

When _x <= 10:
temp remained 0.

Impact:

- Incorrect state updates
- Logic confusion
- Unexpected behavior

Remediation:

The patched version initializes temp and validates
input before updating storage.

Patched Code:

uint256 temp = 0;

require(_x > 0, "Invalid input");

temp = _x + _y;

storedValue = temp;

Result:

Issue successfully fixed.

=========================================================
Finding #3: Misleading State-Changing Function
=========================================================

Severity: Informational

Status: Fixed

Location:
multiply()

Description:

The vulnerable contract mixed local calculations
with storage writes, making behavior less obvious.

The patched multiply() function performs only
temporary computation and does not modify storage.

Patched Code:

function multiply(uint256 _a, uint256 _b)
    public
    pure
    returns (uint256 result)
{
    result = _a * _b;
}

Result:

Issue successfully fixed.

=========================================================
Residual Observation
=========================================================

Severity: Informational

Location:
safeLogic()

Observation:

Any user can call safeLogic() and modify
storedValue.

This is acceptable for a learning contract.

However, if storedValue represented critical
protocol state, access control should be added.

Example:

modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

=========================================================
Conclusion
=========================================================

Fixed Issues:
✓ Unnecessary storage writes removed
✓ Local variables properly initialized
✓ Pure calculations isolated from storage
✓ Multiplication uses temporary local variables only

Remaining Concern:
• No access control on safeLogic() (Informational)

Overall Security Rating:
Low Risk (Educational Contract)
*/
//Patched code
contract LocalUintVariable {

    uint256 public storedValue;

    function calculateSum(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256)
    {
        // properly initialized local variable
        uint256 sum = _a + _b;

        return sum;
    }

    function safeLogic(uint256 _x, uint256 _y)
        public
    {
        // always initialized safely
        uint256 temp = 0;

        require(_x > 0, "Invalid input");

        temp = _x + _y;

        storedValue = temp;
    }

    function multiply(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256 result)
    {
        // pure local computation only
        result = _a * _b;
    }
}