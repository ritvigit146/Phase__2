// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create calldata uint input
CONCEPT: External immutable input
=========================================================

OBJECTIVE

- Learn how external function inputs work
- Understand calldata in Solidity
- Learn immutable input behavior
- Understand difference between calldata, memory, and storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata:
- temporary input area
- read-only
- immutable
- cheaper than memory

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Function arguments from external calls
arrive through calldata.

Calldata exists only during execution.

---------------------------------------------------------
WHY CALLDATA MATTERS
---------------------------------------------------------

Using calldata correctly:
- saves gas
- prevents unnecessary copying
- improves efficiency

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata used heavily in:

- external function parameters
- DeFi protocols
- routers
- token transfers
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata used efficiently?
- Are unnecessary memory copies present?
- Are inputs validated?
- Can attacker abuse external inputs?
- Is immutability understood?

=========================================================
*/
contract CalldataUintInputVul{

    uint256 public storedNumber;

    // VULNERABILITY:
    // Anyone can overwrite storedNumber
    function saveInput(uint256 _number) external {
        storedNumber = _number;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
readInput(50)

EVM ACTIONS:

1. External transaction sent
2. Input encoded into calldata
3. _number read from calldata
4. Value returned
5. Calldata discarded after execution

---------------------------------------------------------

IMPORTANT

Nothing stored permanently.

=========================================================

CALL:
saveInput(777)

EVM ACTIONS:

1. Input arrives through calldata
2. _number read
3. storedNumber updated in storage
4. Blockchain state changes permanently

---------------------------------------------------------

FINAL STORAGE:

storedNumber = 777

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readInput(50)

EXPECTED:
50

---------------------------------------------------------

STEP 3:
Call:
doubleInput(10)

EXPECTED:
20

---------------------------------------------------------

STEP 4:
Call:
saveInput(999)

---------------------------------------------------------

STEP 5:
Call:
storedNumber()

EXPECTED:
999

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass zero

EXPECTED:
Works correctly

---------------------------------------------------------

TEST:
Pass max uint256

EXPECTED:
Works unless arithmetic overflow occurs

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Calldata recreated every execution

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA IS:

- temporary
- read-only
- external input data

---------------------------------------------------------

AFTER FUNCTION ENDS:
Calldata disappears automatically.

---------------------------------------------------------

VERY IMPORTANT

You cannot permanently modify calldata.

=========================================================
CALLDATA VS MEMORY VS STORAGE
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Temporary

Read-only

Cheapest

External inputs

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Temporary

Mutable

More expensive than calldata

---------------------------------------------------------
STORAGE
---------------------------------------------------------

Permanent

Most expensive

Persists on blockchain

=========================================================
IMMUTABILITY CONCEPT
=========================================================

CALLDATA INPUTS ARE IMMUTABLE

Meaning:
they cannot be modified directly.

---------------------------------------------------------

THIS FAILS:

_number = 100;

(for reference-type calldata variables)

---------------------------------------------------------

Reason:
calldata is read-only.

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
Cheaper than memory

---------------------------------------------------------

Reason:
No unnecessary copying.

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. INPUT VALIDATION
---------------------------------------------------------

External calldata is attacker-controlled.

Always validate inputs.

---------------------------------------------------------
2. GAS OPTIMIZATION
---------------------------------------------------------

Auditors check:
whether calldata should replace memory.

---------------------------------------------------------
3. IMMUTABILITY ASSUMPTIONS
---------------------------------------------------------

Developers must understand:
calldata cannot be modified.

---------------------------------------------------------
4. LARGE INPUT DOS
---------------------------------------------------------

Huge calldata inputs may:
increase gas consumption.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends malicious input values.

Without validation:
protocol logic may break.

---------------------------------------------------------

ANOTHER RISK

Large attacker-controlled calldata arrays
may create DOS via gas exhaustion.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata uint array
2. Loop through values
3. Return total sum

BONUS:
Compare gas:
memory array vs calldata array

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata stores external input data
- Calldata is temporary
- Calldata is read-only
- Calldata cheaper than memory
- Storage persists permanently
- External inputs are attacker-controlled
- Storage writes consume most gas
- Calldata improves gas efficiency
- Inputs disappear after execution
- Auditors inspect input handling carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in saveInput()

Severity: Medium because unauthorized users can modify contract state.

Location:
Contract: CalldataUintInputVul
Function: saveInput()

Vulnerability Description:

The saveInput() function allows any external user to modify
the storedNumber state variable because no access control
mechanism is implemented.

Impact:

An attacker can overwrite the stored value with arbitrary data.

If this variable controlled critical protocol logic such as:

* pricing calculations
* treasury configuration
* governance parameters
* protocol settings

then unauthorized users could manipulate system behavior.

Proof of Concept:

1. Deploy contract

2. User A calls:

   saveInput(100)

3. Contract state becomes:

   storedNumber = 100

4. Attacker calls:

   saveInput(999999)

5. Contract state changes successfully:

   storedNumber = 999999

6. Attacker has modified protocol state without authorization.

Root Cause:

The function is declared external without any authorization checks.

No require() statement validates the caller identity before
updating the storedNumber state variable.

Vulnerable Code:

function saveInput(uint256 _number) external {
storedNumber = _number;
}

Recommendation:

Restrict access using an owner check or role-based access control.

Example:

address public owner;

constructor() {
owner = msg.sender;
}

modifier onlyOwner() {
require(msg.sender == owner, "Not owner");
_;
}

function saveInput(uint256 _number)
external
onlyOwner
{
storedNumber = _number;
}

Patched Status:

FIXED

The patched contract introduces an owner variable and
onlyOwner modifier, ensuring that only the authorized
owner can modify storedNumber.

*/

//Patched code
contract CalldataUintInput_Patched {

    uint256 public storedNumber;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Not owner"
        );
        _;
    }

    function saveInput(
        uint256 _number
    )
        external
        onlyOwner
    {
        storedNumber = _number;
    }
}