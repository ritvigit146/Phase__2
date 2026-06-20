// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass large calldata array
CONCEPT: Input scaling
=========================================================

OBJECTIVE

- Learn how large calldata arrays behave
- Understand input scaling risks
- Learn gas impact of large external inputs
- Understand DOS risks from unbounded arrays

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Calldata arrays are efficient,
but VERY LARGE arrays still consume gas.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even though calldata avoids memory copying:

Loops over huge arrays still:
- consume gas
- increase execution time
- may exceed block gas limit

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many real-world smart contract failures happen because:
functions cannot scale with large inputs.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large calldata arrays appear in:

- batch token transfers
- multicall systems
- governance voting
- Merkle proofs
- NFT batch minting
- swap routers

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can attacker pass massive arrays?
- Are loops bounded safely?
- Can function become unusable?
- Is pagination needed?
- Are gas limits considered?

=========================================================
*/
contract LargeCalldataArrayVulnerable {

    uint256 public totalProcessed;

    function processLargeArray(
        uint256[] calldata _numbers
    )
        external
        returns (uint256)
    {
        uint256 total = 0;

        // VULNERABILITY:
        // Unbounded loop over user-controlled array
        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        totalProcessed = total;

        return total;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
processLargeArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Loop reads values directly
3. No memory copy created
4. Gas consumed per iteration
5. Result stored permanently

---------------------------------------------------------

FINAL STORAGE:

totalProcessed = 6

=========================================================

CALL:
processLargeArray(VERY LARGE ARRAY)

OBSERVE:

- many loop iterations
- much higher gas usage
- possible out-of-gas failure

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
processLargeArray([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 3:
Call:
totalProcessed()

EXPECTED:
6

---------------------------------------------------------

STEP 4:
Call:
getArraySize([10,20,30,40])

EXPECTED:
4

---------------------------------------------------------

STEP 5:
Pass larger arrays

OBSERVE:
Gas usage increases significantly

---------------------------------------------------------

STEP 6:
Call:
safeProcessing()

WITH:
More than 100 elements

EXPECTED:
Transaction reverts

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
Returns 0

---------------------------------------------------------

TEST:
Pass single-element array

EXPECTED:
Handled correctly

---------------------------------------------------------

TEST:
Pass extremely large array

OBSERVE:
Possible:
- out-of-gas
- transaction failure
- scalability issue

=========================================================
IMPORTANT SCALING UNDERSTANDING
=========================================================

CALLDATA IS EFFICIENT,
BUT NOT FREE.

---------------------------------------------------------

LOOP COST STILL EXISTS.

---------------------------------------------------------

EACH ITERATION:
Consumes gas.

=========================================================
WHY LARGE INPUTS ARE DANGEROUS
=========================================================

ATTACKERS CAN SUBMIT:
Very large arrays.

---------------------------------------------------------

RESULT:
- excessive gas usage
- DOS conditions
- unusable functions

=========================================================
CALLDATA VS MEMORY COST
=========================================================

CALLDATA:
Cheaper than memory

---------------------------------------------------------

BUT:
Huge calldata arrays still expensive
when heavily processed.

=========================================================
INPUT LIMITING
=========================================================

THIS IS IMPORTANT:

require(_numbers.length <= 100)

---------------------------------------------------------

WHY?

Prevents:
- gas exhaustion
- scalability failures
- DOS attacks

=========================================================
GAS OBSERVATION
=========================================================

SMALL ARRAYS:
Cheap

---------------------------------------------------------

LARGE ARRAYS:
Expensive

---------------------------------------------------------

VERY LARGE ARRAYS:
Possible out-of-gas failure

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA LARGE INPUTS
---------------------------------------------------------

Most important concern.

Huge arrays may:
- exceed gas limit
- break protocol functions

---------------------------------------------------------
2. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over attacker-controlled input
are dangerous.

---------------------------------------------------------
3. INPUT LIMITING
---------------------------------------------------------

Auditors check for:
- max array size
- pagination
- batching protections

---------------------------------------------------------
4. SCALABILITY FAILURES
---------------------------------------------------------

Functions may work initially,
then fail as usage grows.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends massive calldata array.

Loop consumes excessive gas.

Result:
- transaction failure
- DOS condition
- unusable protocol logic

---------------------------------------------------------

REAL-WORLD IMPACT

Many smart contracts became:
- permanently unusable
- too expensive to call

because loops were unbounded.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add pagination support
2. Process only partial array ranges
3. Add max gas-safe batch size

BONUS:
Measure gas for:
10 vs 100 vs 1000 elements

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata arrays are efficient
- Large inputs still consume gas
- Loops scale linearly with size
- Unbounded loops create DOS risks
- Gas exhaustion can break protocols
- Input limiting improves safety
- External inputs are attacker-controlled
- Scalability matters in Solidity
- Pagination prevents large-loop failures
- Auditors inspect scaling behavior carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Loop Over User-Controlled Calldata Array

Severity: Low because an attacker can cause excessive gas consumption
and transaction failures by supplying very large arrays.

Location: Contract: LargeCalldataArray
Function: processLargeArray()

Vulnerability Description:

The processLargeArray() function iterates over the entire calldata
array without enforcing a maximum length.

Since _numbers is fully controlled by the caller, an attacker can
submit extremely large arrays, causing the loop to consume excessive gas.

As the array size grows, the function becomes increasingly expensive
to execute and may eventually exceed the block gas limit.

Impact:

- Excessive gas consumption
- Transaction failures due to out-of-gas errors
- Potential denial-of-service conditions
- Reduced protocol scalability
- Function may become unusable with sufficiently large inputs

Proof of Concept:

1. Deploy contract

2. Call:
   processLargeArray([1,2,3])

   Result:
   Function executes successfully

3. Call:
   processLargeArray(veryLargeArray)

   Example:
   Array containing thousands of elements

4. Observe:

   - Significantly increased gas consumption
   - Potential out-of-gas revert
   - Function becomes difficult to execute

Root Cause:

The function performs an unbounded loop over a user-controlled
calldata array.

No validation exists to restrict:

- _numbers.length
- maximum batch size
- processing limits

Vulnerable code:

for (uint256 i = 0; i < _numbers.length; i++) {
    total += _numbers[i];
}

Recommendation:

Restrict the maximum allowed array size before processing.

Example:

require(
    _numbers.length <= 100,
    "Array too large"
);

Alternatively, implement pagination or batch processing
to safely handle large datasets.

Example:

function processBatch(
    uint256[] calldata _numbers,
    uint256 start,
    uint256 end
)
    external
    pure
    returns (uint256)
{
    require(end <= _numbers.length);

    uint256 total;

    for (uint256 i = start; i < end; i++) {
        total += _numbers[i];
    }

    return total;
}

*/

//Patched code
contract LargeCalldataArrayPatched {

    uint256 public totalProcessed;

    uint256 public constant MAX_BATCH_SIZE = 100;

    function processLargeArray(
        uint256[] calldata _numbers
    )
        external
        returns (uint256)
    {
        require(
            _numbers.length <= MAX_BATCH_SIZE,
            "Array too large"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        totalProcessed = total;

        return total;
    }
}