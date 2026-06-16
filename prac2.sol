// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Update state variable multiple times
CONCEPT: State overwrite behavior
=========================================================

OBJECTIVE

- Learn how state variables behave when updated repeatedly
- Understand overwrite behavior in Solidity storage
- Learn that old values are replaced permanently
- Understand why overwriting important data can be dangerous

---------------------------------------------------------
CORE CONCEPT
---------------------------------------------------------

STATE VARIABLES:
- Stored permanently in blockchain storage
- Can be updated many times
- New value overwrites old value
- Old value is NOT automatically preserved

IMPORTANT:
Blockchain stores current state,
NOT full variable history inside storage.

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Is overwriting intended?
- Should previous values be preserved?
- Can attackers overwrite critical data?
- Is important state lost accidentally?
- Should events/history tracking exist?

=========================================================
*/

contract StateOverwriteVul{

    uint256 public number;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function updateNumber(uint256 _newNumber) public {
        require(msg.sender == owner, "Only owner can update");
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

number = 0

---------------------------------------------------------

CALL:
updateNumber(10)

EVM ACTIONS:
1. Transaction received
2. _newNumber comes through calldata
3. Storage slot for "number" updated
4. number becomes 10

---------------------------------------------------------

CALL:
updateNumber(50)

EVM ACTIONS:
1. Previous value = 10
2. Storage slot updated again
3. Old value replaced
4. number becomes 50

IMPORTANT:
Old value 10 is overwritten.

---------------------------------------------------------

CALL:
updateNumber(999)

RESULT:
number = 999

Only latest value exists in storage.

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

EXPECTED:
number() => 0

---------------------------------------------------------

STEP 2:
Call:
updateNumber(10)

EXPECTED:
number() => 10

---------------------------------------------------------

STEP 3:
Call:
updateNumber(500)

EXPECTED:
number() => 500

OBSERVE:
Old value 10 no longer exists in storage.

---------------------------------------------------------

STEP 4:
Call:
updateNumber(777)

EXPECTED:
number() => 777

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
updateNumber(0)

EXPECTED:
Value resets to zero

---------------------------------------------------------

TEST:
Repeated updates

Call:
updateNumber(1)
updateNumber(2)
updateNumber(3)
updateNumber(4)

EXPECTED:
Final stored value = 4

=========================================================
IMPORTANT STORAGE OBSERVATION
=========================================================

STORAGE SLOT BEHAVIOR

The same storage slot gets updated repeatedly.

Example:

Initial:
slot0 => 0

After updateNumber(10):
slot0 => 10

After updateNumber(50):
slot0 => 50

After updateNumber(999):
slot0 => 999

Old values are replaced.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

POTENTIAL PROBLEM

If this variable stored:

- admin address
- token price
- protocol fee
- treasury balance
- voting result

then accidental or malicious overwrites
could break protocol logic.

---------------------------------------------------------

AUDITOR QUESTIONS

- Should overwrite be allowed?
- Is history needed?
- Should updates be restricted?
- Should old values be logged in events?
- Can attackers spam updates?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose number represents protocol fee.

Attacker repeatedly calls:

updateNumber(0)

or

updateNumber(999999)

Possible impact:
- protocol malfunction
- incorrect calculations
- financial manipulation

---------------------------------------------------------

REAL-WORLD ISSUE

Many smart contract hacks happen because:
- important state gets overwritten
- validation missing
- access control missing

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Previous value is stored in another variable
2. Every update saves:
   - old value
   - new value

HINT:
Create:
uint256 public previousNumber;

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- State variables live in storage
- Storage updates overwrite old values
- Latest value replaces previous value
- Storage writes cost gas
- Overwriting important state can be dangerous
- Auditors inspect overwrite behavior carefully
- History is NOT automatically preserved
- Access control is critical for state updates

=========================================================
*/
/*
Audit Report

Title: Loss of Previous State Due to Overwrite

Severity: Low ecause it's mainly a data/history preservation issue, not an immediate security exploit like 
missing access control or fund theft

Location: Contract: StateOverwriteVul

Function: updateNumber()

Vulnerability Description: The updateNumber() function overwrites the number state variable without 
preserving its previous value.Each new update permanently replaces the old value in storage. As a result, 
historical state information is lost and cannot be accessed by the contract.

Impact: Previous values are permanently lost after each update, making it difficult to track state changes
and review contract behavior over time.

Loss of previous state values may:

* Reduce auditability
* Make debugging difficult
* Prevent recovery of important information
* Cause issues if protocol logic depends on historical values

If the variable represented critical data such as:

* protocol fee
* token price
* voting result
* configuration parameter

then previous values would be unavailable after an update.

Proof of Concept:
               1. Deploy contract

               2. Call: updateNumber(10)
               State: number = 10

               3. Call: updateNumber(50)
               State:number = 50

               4. Observe: Previous value (10) is no longer stored inside the contract.

Root Cause:
The function directly overwrites storage:
number = _newNumber;

No mechanism exists to preserve the old value before the update occurs.

Recommendation:

Store the previous value before overwriting the current value.
*/

// Patched code
contract StateOverwrite {

    uint256 public number;
    uint256 public previousNumber;

    function updateNumber(uint256 _newNumber) public {

        // Save old value before overwrite
        previousNumber = number;

        // Store new value
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }

    function getPreviousNumber() public view returns (uint256) {
        return previousNumber;
    }
}

