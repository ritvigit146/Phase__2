// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete storage variable
CONCEPT: Reset behavior
=========================================================

OBJECTIVE

- Understand delete on storage variables
- Learn default reset values
- Observe how storage is cleared
- Understand delete behavior on arrays
- Think like auditor about reset logic

---------------------------------------------------------
CORE CONCEPT
---------------------------------------------------------

delete variable;

Resets variable to DEFAULT VALUE.

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

uint256  => 0
bool     => false
address  => address(0)
string   => ""
array    => empty array

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

delete DOES NOT:
- erase blockchain history
- physically remove storage forever
- refund all gas automatically

It only resets current state values.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

delete is commonly used for:

- resetting balances
- clearing temporary state
- removing users
- resetting arrays
- invalidating data

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- improper reset logic
- delete ordering bugs
- array holes
- broken accounting
- stale storage references

=========================================================
*/
contract DeleteStorageVariableVul {

    uint256[] public numbers;

    constructor() {
        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
    }

    function deleteArrayIndex(uint256 _index) public {
        delete numbers[_index];
    }

    function getArray()
        public
        view
        returns(uint256[] memory)
    {
        return numbers;
    }
}
/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

number    = 100
isActive  = true
owner     = 0x111...
message   = "Blockchain"

numbers = [10,20,30]

---------------------------------------------------------

CALL:
deleteNumber()

EVM ACTIONS:

1. Storage slot located
2. Value reset to default
3. number becomes 0

---------------------------------------------------------

FINAL STATE

number = 0

=========================================================
DELETE BOOL FLOW
=========================================================

CALL:
deleteBool()

EXPECTED:

isActive = false

=========================================================
DELETE ADDRESS FLOW
=========================================================

CALL:
deleteOwner()

EXPECTED:

owner = address(0)

=========================================================
DELETE STRING FLOW
=========================================================

CALL:
deleteMessage()

EXPECTED:

message = ""

=========================================================
DELETE ARRAY FLOW
=========================================================

INITIAL ARRAY

[10,20,30]

---------------------------------------------------------

CALL:
deleteArray()

---------------------------------------------------------

FINAL ARRAY

[]

length = 0

=========================================================
DELETE ARRAY INDEX FLOW
=========================================================

INITIAL ARRAY

[10,20,30]

---------------------------------------------------------

CALL:
deleteArrayIndex(1)

---------------------------------------------------------

FINAL ARRAY

[10,0,30]

IMPORTANT:

Length remains 3.

delete only resets element value.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
number()

EXPECTED:
100

---------------------------------------------------------

STEP 3:
Call:
deleteNumber()

---------------------------------------------------------

STEP 4:
Call:
number()

EXPECTED:
0

=========================================================
ARRAY TESTING
=========================================================

STEP 1:
Call:
getArray()

EXPECTED:

[10,20,30]

---------------------------------------------------------

STEP 2:
Call:
deleteArrayIndex(1)

---------------------------------------------------------

STEP 3:
Call:
getArray()

EXPECTED:

[10,0,30]

---------------------------------------------------------

STEP 4:
Call:
deleteArray()

---------------------------------------------------------

STEP 5:
Call:
getArray()

EXPECTED:

[]

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

DELETE RESETS STORAGE SLOT
TO DEFAULT VALUE.

---------------------------------------------------------

EXAMPLE

BEFORE:

slotX => 100

AFTER delete:

slotX => 0

---------------------------------------------------------

FOR ARRAYS

delete array:
- resets length
- clears elements logically

delete array[index]:
- resets only one slot
- does NOT shrink array

=========================================================
GAS OBSERVATION
=========================================================

DELETE may provide partial gas refunds
for clearing storage slots.

However:
refund rules changed across Ethereum upgrades.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DELETE ORDERING BUGS
---------------------------------------------------------

Dangerous pattern:

delete balances[user];

totalSupply -= balances[user];

RESULT:
balances[user] already became 0

Accounting breaks.

---------------------------------------------------------
2. ARRAY HOLES
---------------------------------------------------------

delete array[index]

creates sparse arrays.

Risk:
- broken iteration logic
- unexpected zeros
- accounting bugs

---------------------------------------------------------
3. STALE REFERENCES
---------------------------------------------------------

Deleting value may not clean all references.

Other structures may still point to old data.

---------------------------------------------------------
4. FALSE ASSUMPTION
---------------------------------------------------------

delete DOES NOT erase blockchain history.

All old states remain permanently visible.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker abuses improper delete logic.

Example:
- reset balance before fee calculation
- bypass accounting checks
- exploit sparse arrays

---------------------------------------------------------

REAL-WORLD IMPACT

Many protocols suffered:
- accounting mismatches
- reward bugs
- broken iteration logic

due to incorrect reset behavior.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Array element removal shrinks array properly
2. No holes remain in array

EXAMPLE:

BEFORE:
[10,20,30]

Remove index 1

AFTER:
[10,30]

HINT:

Use:
- swap element with last value
- pop()

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- delete resets values to defaults
- delete does not erase blockchain history
- arrays behave differently from simple variables
- deleting array index creates holes
- storage reset order matters
- delete can break accounting logic
- auditors inspect cleanup behavior carefully
- sparse arrays create hidden bugs
- storage design affects security
- reset logic must be carefully audited

=========================================================
*/
/*
Audit Report

Title: Array Hole Creation Due to delete on Array Index

Severity: Medium because array integrity can be broken and unexpected zero values may affect protocol logic

Location:
Contract: DeleteStorageVariableVul
Function: deleteArrayIndex()

Vulnerability Description:

The deleteArrayIndex() function uses:

delete numbers[_index];

This does not remove the element from the array.

Instead, it resets the element to its default value (0 for uint256)
while keeping the array length unchanged.

As a result, sparse arrays (arrays with holes) are created.

Example:

Before:
[10,20,30]

After deleteArrayIndex(1):
[10,0,30]

Length remains:
3

Impact:

An attacker or user can create unexpected zero values inside the array.

If the array is later used for:

- accounting
- reward calculations
- voting logic
- participant tracking
- iteration-based calculations

the protocol may process invalid data and produce incorrect results.

Proof of Concept:

1. Deploy contract

2. Call:
   getArray()

   Result:
   [10,20,30]

3. Call:
   deleteArrayIndex(1)

4. Call:
   getArray()

   Result:
   [10,0,30]

5. Observe:
   Array length is still 3
   Element was not removed

Root Cause:

The contract incorrectly assumes:

delete numbers[_index];

removes an array element.

In Solidity, delete only resets the value to its default value.
It does not shrink the array.

Recommendation:

Use the swap-and-pop pattern to properly remove elements.

Example:

require(_index < numbers.length, "Invalid index");

numbers[_index] = numbers[numbers.length - 1];
numbers.pop();

This:

- removes the element
- shrinks the array
- prevents holes
- is gas efficient

Status:

Fixed in DeleteStorageVariable contract using swap-and-pop removal.
*/
//Patched code
contract DeleteStorageVariable {

    uint256[] public numbers;

    constructor() {
        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
    }

    function removeArrayIndex(uint256 _index) public {
        require(_index < numbers.length, "Invalid index");

        numbers[_index] = numbers[numbers.length - 1];

        numbers.pop();
    }

    function getArray()
        public
        view
        returns(uint256[] memory)
    {
        return numbers;
    }
}