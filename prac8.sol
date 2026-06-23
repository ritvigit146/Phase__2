// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Push multiple values into array
CONCEPT: Dynamic storage growth
=========================================================

OBJECTIVE

- Learn how arrays grow dynamically
- Understand repeated push() operations
- Learn how storage expands on-chain
- Understand gas implications of growing arrays

---------------------------------------------------------
CORE CONCEPT
---------------------------------------------------------

Dynamic arrays automatically increase in size
when new elements are pushed.

Each new value:
- gets new storage slot
- increases array length
- consumes additional gas

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Dynamic arrays are used for:

- transaction history
- staking participants
- NFT ownership records
- governance proposals
- vote tracking
- reward lists

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Blockchain storage is PERMANENT.

Every pushed value increases:
- storage usage
- blockchain state size
- future execution cost

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unlimited array growth
- storage abuse possibilities
- loop DOS vulnerabilities
- gas scalability problems
- attacker-controlled storage expansion

=========================================================
*/
contract DynamicArrayGrowthVul {

    uint256[] public numbers;

    function addMultipleValues(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) public {

        numbers.push(_value1);
        numbers.push(_value2);
        numbers.push(_value3);
    }

    function getNumber(uint256 _index)
        public
        view
        returns (uint256)
    {
        return numbers[_index];
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}
/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

numbers = []

length = 0

---------------------------------------------------------

CALL:
addMultipleValues(10, 20, 30)

EVM ACTIONS:

1. Function parameters arrive via calldata
2. First push() executes
3. Array length increases
4. Value stored in new slot

---------------------------------------------------------

FIRST PUSH

numbers[0] = 10

length = 1

---------------------------------------------------------

SECOND PUSH

numbers[1] = 20

length = 2

---------------------------------------------------------

THIRD PUSH

numbers[2] = 30

length = 3

---------------------------------------------------------

FINAL ARRAY

[10, 20, 30]

---------------------------------------------------------

CALL:
getNumber(1)

EXPECTED:
20

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
getLength()

EXPECTED:
0

---------------------------------------------------------

STEP 3:
Call:
addMultipleValues(10,20,30)

---------------------------------------------------------

STEP 4:
Call:
getLength()

EXPECTED:
3

---------------------------------------------------------

STEP 5:
Call:
getNumber(0)

EXPECTED:
10

---------------------------------------------------------

STEP 6:
Call:
getNumber(1)

EXPECTED:
20

---------------------------------------------------------

STEP 7:
Call:
getNumber(2)

EXPECTED:
30

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Push zeros

addMultipleValues(0,0,0)

EXPECTED:
Values stored successfully

---------------------------------------------------------

TEST:
Push very large values

EXPECTED:
Stored correctly

---------------------------------------------------------

TEST:
Call function repeatedly

Example:
addMultipleValues(1,2,3)
addMultipleValues(4,5,6)

EXPECTED ARRAY:

[1,2,3,4,5,6]

OBSERVE:
Array keeps growing dynamically.

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

DYNAMIC STORAGE GROWTH

Each push():
- allocates new storage slot
- increases permanent blockchain state

---------------------------------------------------------

STORAGE EXAMPLE

After first call:

slotA     => array length = 3
slotHash0 => 10
slotHash1 => 20
slotHash2 => 30

---------------------------------------------------------

AFTER SECOND CALL

length = 6

New values appended sequentially.

=========================================================
GAS OBSERVATION
=========================================================

MORE PUSH OPERATIONS
= MORE STORAGE WRITES
= HIGHER GAS COST

---------------------------------------------------------

Storage writes are among the MOST expensive
operations in Solidity.

Large arrays can become costly over time.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNBOUNDED STORAGE GROWTH
---------------------------------------------------------

Current contract has no limit.

Attackers can continuously grow array.

Risk:
- storage bloat
- higher execution costs
- protocol scalability issues

---------------------------------------------------------
2. LOOP DOS RISK
---------------------------------------------------------

Future loops over huge arrays may fail.

Example dangerous pattern:

for(uint i=0; i<numbers.length; i++)

Large arrays may exceed gas limit.

---------------------------------------------------------
3. ATTACKER-CONTROLLED STORAGE
---------------------------------------------------------

Users directly control storage expansion.

Auditors check:
- limits
- rate controls
- pruning mechanisms

---------------------------------------------------------
4. PERMANENT STATE EXPANSION
---------------------------------------------------------

Blockchain storage is expensive forever.

Poor storage design creates:
- protocol inefficiency
- long-term scaling issues

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker repeatedly calls:

addMultipleValues(...)

thousands of times.

RESULT:
- massive storage growth
- protocol becomes expensive
- loops become unusable

---------------------------------------------------------

REAL-WORLD ISSUE

Several smart contracts suffered DOS problems
because arrays became too large to process.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Maximum array length is 10
2. Further push attempts should fail

HINT:

Use:
require(numbers.length < 10)

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Dynamic arrays grow automatically
- push() appends new elements
- Each push increases storage usage
- Storage growth increases gas cost
- Arrays persist permanently on-chain
- Repeated pushes create scalability concerns
- Large arrays can cause DOS vulnerabilities
- Unbounded storage is dangerous
- Auditors inspect storage growth carefully
- Gas efficiency matters in array design

=========================================================
*/
/*
Audit Report
Title

Unbounded Dynamic Array Growth

Severity

Low

The issue does not directly enable theft of funds or privilege escalation. However, unrestricted storage growth can increase protocol 
costs and create future scalability and denial-of-service risks.

Location

Contract: DynamicArrayGrowthVul
Function: addMultipleValues()

Vulnerability Description

The addMultipleValues() function allows any user to continuously append new elements to the numbers array.

Because no maximum length restriction exists, the array can grow indefinitely, resulting in permanent blockchain storage expansion.

An attacker can repeatedly call the function and force the contract to consume increasing amounts of storage.

Impact

Unbounded storage growth may:

Increase blockchain state size
Increase long-term storage costs
Reduce protocol scalability
Create future gas-related issues
Contribute to denial-of-service risks if loops are later introduced

Large arrays can become expensive or impossible to process in future contract upgrades.

Proof of Concept
Step 1

Deploy contract.

Step 2

Call:

addMultipleValues(1,2,3);

State:

numbers = [1,2,3]
length = 3
Step 3

Call repeatedly:

addMultipleValues(4,5,6);
addMultipleValues(7,8,9);
addMultipleValues(10,11,12);

State:

numbers = [1,2,3,4,5,6,7,8,9,10,11,12]
length = 12
Step 4

Continue calling the function.

Result:

Array grows without limit
Storage consumption increases permanently
Root Cause

The function performs multiple push() operations without checking array size.

numbers.push(_value1);
numbers.push(_value2);
numbers.push(_value3);

No maximum length validation exists.

Recommendation

Implement a maximum array size restriction before appending new values.

Example:

require(
    numbers.length + 3 <= 10,
    "Maximum array length reached"
);

This ensures the array cannot exceed the intended limit.
*/

// Patched code
contract DynamicArrayGrowth {

    uint256[] public numbers;

    function addMultipleValues(
        uint256 _value1,
        uint256 _value2,
        uint256 _value3
    ) public {

        require(
            numbers.length + 3 <= 10,
            "Maximum array length reached"
        );

        numbers.push(_value1);
        numbers.push(_value2);
        numbers.push(_value3);
    }

    function getNumber(uint256 _index)
        public
        view
        returns (uint256)
    {
        return numbers[_index];
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}