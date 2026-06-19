// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create calldata array input
CONCEPT: Efficient external data
=========================================================

OBJECTIVE

- Learn how calldata arrays work
- Understand efficient external data handling
- Learn why calldata is cheaper than memory
- Understand immutable external array behavior

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata arrays:
- hold external input data
- are temporary
- are read-only
- avoid unnecessary memory copying

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Using calldata for external arrays:
saves gas.

Reason:
Data is NOT copied into memory automatically.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Gas optimization is critical in:
- DeFi
- NFT projects
- routers
- batch operations
- governance systems

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata arrays heavily used in:

- batch token transfers
- swap routers
- multicall systems
- governance voting
- staking protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata used instead of memory?
- Are loops bounded safely?
- Can attacker provide huge arrays?
- Is gas exhaustion possible?
- Are inputs validated?

=========================================================
*/
contract CalldataArrayExampleVul {

    uint256[] public storedValues;

    /*
        VULNERABILITY:
        Unbounded loop over attacker-controlled array.
    */
    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {
        for (uint256 i = 0; i < _numbers.length; i++) {

            storedValues.push(_numbers[i]);
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
calculateSum([1,2,3])

EVM ACTIONS:

1. External input encoded into calldata
2. _numbers references calldata directly
3. Loop reads values efficiently
4. No full memory copy created
5. Result returned
6. Calldata discarded after execution

---------------------------------------------------------

RESULT:
6

=========================================================

CALL:
saveValues([10,20,30])

EVM ACTIONS:

1. Array arrives in calldata
2. Values read individually
3. Values copied into storage
4. Blockchain state updated permanently

---------------------------------------------------------

FINAL STORAGE:

[10,20,30]

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readArray([1,2,3])

EXPECTED:
[1,2,3]

---------------------------------------------------------

STEP 3:
Call:
getArrayLength([10,20,30,40])

EXPECTED:
4

---------------------------------------------------------

STEP 4:
Call:
calculateSum([5,5,5])

EXPECTED:
15

---------------------------------------------------------

STEP 5:
Call:
saveValues([100,200])

---------------------------------------------------------

STEP 6:
Call:
storedValues(0)

EXPECTED:
100

---------------------------------------------------------

STEP 7:
Call:
storedValues(1)

EXPECTED:
200

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
Works correctly

---------------------------------------------------------

TEST:
Pass huge array

OBSERVE:
Higher gas consumption

---------------------------------------------------------

TEST:
Pass single-element array

EXPECTED:
Handled correctly

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

THIS PARAMETER:

uint256[] calldata _numbers

---------------------------------------------------------

MEANS:

- external input array
- temporary
- read-only
- efficient

---------------------------------------------------------

NO FULL MEMORY COPY CREATED.

=========================================================
WHY CALLDATA IS CHEAPER
=========================================================

MEMORY ARRAY:
Copies all data into memory.

---------------------------------------------------------

CALLDATA ARRAY:
Reads directly from external input.

---------------------------------------------------------

RESULT:
Lower gas usage.

=========================================================
CALLDATA IMMUTABILITY
=========================================================

CALLDATA ARRAYS ARE READ-ONLY.

---------------------------------------------------------

THIS FAILS:

_numbers[0] = 999;

---------------------------------------------------------

Reason:
calldata cannot be modified.

=========================================================
CALLDATA VS MEMORY ARRAY
=========================================================

---------------------------------------------------------
CALLDATA ARRAY
---------------------------------------------------------

Temporary

Read-only

Cheaper

No automatic copy

---------------------------------------------------------
MEMORY ARRAY
---------------------------------------------------------

Temporary

Mutable

More expensive

Requires copying

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
Gas efficient

---------------------------------------------------------

MEMORY:
More expensive due to copying

---------------------------------------------------------

LARGE ARRAYS:
Still expensive because loops consume gas

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA LARGE ARRAYS
---------------------------------------------------------

Huge calldata arrays may:
- consume excessive gas
- exceed block gas limits

---------------------------------------------------------
2. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over attacker-controlled arrays
are dangerous.

---------------------------------------------------------
3. INPUT VALIDATION
---------------------------------------------------------

External calldata is attacker-controlled.

Always validate assumptions.

---------------------------------------------------------
4. GAS OPTIMIZATION
---------------------------------------------------------

Auditors often recommend:
calldata instead of memory
for external read-only arrays.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits massive calldata array.

Loop processing becomes expensive.

Possible result:
- DOS condition
- out-of-gas failure

---------------------------------------------------------

REAL-WORLD ISSUE

Improper batch processing has caused:
- uncallable functions
- scalability failures

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Find largest value in calldata array
2. Return maximum number
3. Reject empty arrays

BONUS:
Compare gas:
memory[] vs calldata[] inputs

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata arrays store external input
- Calldata is temporary
- Calldata arrays are read-only
- Calldata avoids memory copying
- Calldata cheaper than memory
- Large arrays still consume gas
- Unbounded loops create DOS risks
- Storage writes are expensive
- External inputs are attacker-controlled
- Auditors inspect calldata efficiency carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Loop Leading to Gas Denial of Service

Severity: Medium because a user can submit excessively large arrays,
causing excessive gas consumption and transaction failures.

Location: Contract: CalldataArrayExampleVul
Function: saveValues()

Vulnerability Description:

The saveValues() function processes a user-supplied calldata array
without enforcing a maximum size.

The function loops through every element in the array and stores it
in contract storage.

Because the array length is fully controlled by the caller,
an attacker can submit an extremely large array and force
the contract to consume excessive gas.

Impact:

An attacker can submit very large arrays resulting in:

* Excessive gas consumption
* Transaction failures
* Reduced contract usability
* Potential denial of service conditions

If this function were part of critical protocol operations,
large inputs could make important transactions impractical to execute.

Proof of Concept:

1. Deploy contract

2. User calls:

   saveValues([1,2,3,4,5])

3. Transaction succeeds

4. Attacker calls:

   saveValues(hugeArray)

   where hugeArray contains thousands of elements

5. The contract attempts to process every element

6. Gas consumption becomes extremely high and the
   transaction may revert due to gas limits

Root Cause:

The function uses an unbounded loop based on
user-controlled input:

for (uint256 i = 0; i < _numbers.length; i++)


No validation is performed on _numbers.length before
processing the array.

Recommendation:

Restrict the maximum array size before entering the loop.
*/

//Patched code
contract CalldataArrayExamplePatched {

    uint256[] public storedValues;

    uint256 public constant MAX_ARRAY_LENGTH = 100;

    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {
        require(
            _numbers.length <= MAX_ARRAY_LENGTH,
            "Array too large"
        );

        for (uint256 i = 0; i < _numbers.length; i++) {

            storedValues.push(_numbers[i]);
        }
    }
}