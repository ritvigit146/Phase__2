// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass huge calldata array
CONCEPT: Gas impact
=========================================================

OBJECTIVE

- Understand calldata gas efficiency
- Compare large input handling costs
- Learn why calldata is preferred over memory
- Observe gas impact of large arrays

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

calldata = read-only external input

---------------------------------------------------------

Huge calldata arrays:
do NOT get copied into memory automatically.

---------------------------------------------------------

This makes calldata cheaper than memory.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Gas cost increases with:

- array size
- decoding complexity
- storage writes (if any)
- loops over data

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Large inputs appear in:

- batch transfers
- airdrops
- multicall systems
- oracle feeds
- on-chain aggregation

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- calldata size limits
- loop processing cost
- gas scaling behavior
- DOS via large inputs

=========================================================
CALDATA CONTRACT
=========================================================
*/
contract CalldataGasVul {

    uint256 public totalSum;
    uint256 public totalElements;

    /*
        VULNERABILITY:
        - No limit on calldata array size.
        - Storage write inside loop.
        - Large arrays can consume excessive gas
          and cause transaction failure (Gas DoS).
    */
    function processCalldataArray(
        uint256[] calldata data
    )
        external
    {
        uint256 sum = 0;

        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];

            // Expensive storage write every iteration
            totalElements++;
        }

        totalSum = sum;
    }

    function getTotalElements()
        external
        view
        returns (uint256)
    {
        return totalElements;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy CalldataGas

=========================================================
TRACE:
processCalldataArray()
=========================================================

INPUT:
Huge uint256[] calldata

Example size:
1000 elements

=========================================================
STEP 2
=========================================================

Function starts.

---------------------------------------------------------

sum = 0

=========================================================
STEP 3
=========================================================

Loop begins:

i = 0

=========================================================
STEP 4
=========================================================

Read:

data[0]

---------------------------------------------------------

Add to sum.

---------------------------------------------------------

sum += data[0]

=========================================================
STEP 5
=========================================================

Storage write:

totalElements++

---------------------------------------------------------

IMPORTANT:
This is expensive.

=========================================================
STEP 6
=========================================================

Loop continues:

i = 1 ... 999

=========================================================
IMPORTANT BEHAVIOR
=========================================================

Each iteration:

---------------------------------------------------------
READ
---------------------------------------------------------

from calldata (cheap)

---------------------------------------------------------
WRITE
---------------------------------------------------------

to storage (expensive)

=========================================================
FINAL STEP
=========================================================

After loop:

totalSum = sum

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
totalElements
---------------------------------------------------------

= number of elements processed

---------------------------------------------------------
totalSum
---------------------------------------------------------

= sum of all values

=========================================================
WHY CALDATA IS IMPORTANT
=========================================================

calldata is:

---------------------------------------------------------
READ-ONLY
---------------------------------------------------------

AND

---------------------------------------------------------
NO COPYING INTO MEMORY
---------------------------------------------------------

=========================================================
GAS ADVANTAGE
=========================================================

Compared to memory:

- NO extra copy cost
- NO allocation overhead
- DIRECT access

=========================================================
BUT IMPORTANT
=========================================================

Gas still increases due to:

---------------------------------------------------------
LOOP PROCESSING
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE WRITES
---------------------------------------------------------

=========================================================
MEMORY VS CALDATA COMPARISON
=========================================================

---------------------------------------------------------
calldata
---------------------------------------------------------

- cheapest input
- read-only
- no copying
- best for external inputs

=========================================================

---------------------------------------------------------
memory
---------------------------------------------------------

- copied data
- more gas than calldata
- mutable

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
processCalldataArray([1,2,3,...1000])

---------------------------------------------------------

Observe:
moderate gas usage

=========================================================
TEST 2
=========================================================

Call:
processMemoryArray([...1000 values...])

---------------------------------------------------------

Observe:
higher gas than calldata version

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Large calldata inputs can cause:

---------------------------------------------------------
GAS DOS
---------------------------------------------------------

if processing is heavy.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. LARGE INPUT LOOPS
---------------------------------------------------------

Gas scales linearly.

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

Major gas explosion.

---------------------------------------------------------
3. UNBOUNDED CALDATA SIZE
---------------------------------------------------------

Attacker can send huge arrays.

---------------------------------------------------------
4. DENIAL OF SERVICE
---------------------------------------------------------

Function becomes too expensive.

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- send huge arrays
- force gas exhaustion
- exploit loop scaling
- DOS processing functions

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors check:

- calldata size limits
- loop complexity O(n)
- storage writes per iteration
- gas upper bounds
- worst-case execution cost

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors estimate:

---------------------------------------------------------
MAX ARRAY SIZE IMPACT
---------------------------------------------------------

AND

---------------------------------------------------------
BLOCK GAS LIMIT SAFETY
---------------------------------------------------------

=========================================================
BEST PRACTICES
=========================================================

- Use calldata for external inputs
- Avoid storage writes in loops
- Batch processing carefully
- Enforce input size limits
- Prefer O(1) or O(log n) designs

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Limit array size to 500
2. Compare 500 vs 1000 gas usage
3. Remove storage writes in loop
4. Add batch processing function

BONUS:
Create gas-safe streaming processor.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata is cheapest input type
- Large arrays increase gas linearly
- Storage writes dominate gas cost
- calldata avoids memory copy cost
- loops over large inputs are expensive
- gas scaling can cause DOS
- auditors analyze worst-case input size
- calldata is read-only external input
- optimization reduces execution cost
- input validation is critical for security

=========================================================
*/
/*
Audit Report

Title: Unbounded Calldata Array Can Cause Gas Denial of Service

Severity: Medium because a user can submit an extremely large array,
causing excessive gas consumption and making the function fail.

Location:
Contract: CalldataGasVul
Function: processCalldataArray()

Vulnerability Description:

The processCalldataArray() function accepts an array of arbitrary
length without validating its size.

The function also performs a storage write (totalElements++)
during every loop iteration.

As the input array grows larger, gas consumption increases linearly.
For sufficiently large inputs, the transaction can exceed the block
gas limit and revert.

Impact:

An attacker can submit a very large calldata array, causing:

- Out-of-gas transaction failures
- Denial of Service (DoS)
- Excessive execution costs
- Poor scalability
- Inefficient storage updates

Proof of Concept:

1. Deploy CalldataGasVul.
2. Create a uint256 array containing thousands of elements.
3. Call:

   processCalldataArray(largeArray)

4. Observe:

   - Extremely high gas usage.
   - Transaction may revert due to gas exhaustion.

Root Cause:

The function has no upper bound on the calldata array size and
updates storage during every iteration of the loop.

Recommendation:

- Limit the maximum array size using require().
- Avoid storage writes inside loops.
- Accumulate values in local variables.
- Perform a single storage update after the loop.

Example:

require(data.length <= 500, "Batch size exceeds limit");

uint256 processed = data.length;

for (...) {
    sum += data[i];
}

totalSum = sum;
totalElements += processed;

*/

//Patched code
contract CalldataGas {

    uint256 public totalSum;
    uint256 public totalElements;

    // Maximum safe batch size
    uint256 public constant MAX_BATCH_SIZE = 500;

    /*
        PATCHES:
        1. Limit calldata array size.
        2. Avoid storage writes inside loop.
        3. Update storage once after processing.
    */
    function processCalldataArray(
        uint256[] calldata data
    )
        external
    {
        require(
            data.length <= MAX_BATCH_SIZE,
            "Batch size exceeds limit"
        );

        uint256 sum = 0;

        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }

        // Single storage writes
        totalSum = sum;
        totalElements += data.length;
    }

    function getTotalElements()
        external
        view
        returns (uint256)
    {
        return totalElements;
    }
}