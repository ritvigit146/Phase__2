// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Modify memory array
CONCEPT: Mutable temporary data
=========================================================

OBJECTIVE

- Learn how memory arrays can be modified
- Understand mutable temporary data
- Learn that memory changes do NOT persist
- Understand difference between memory and storage mutation

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory arrays are mutable.

This means:
their values CAN be changed during execution.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Even though memory arrays are mutable:

Changes are TEMPORARY.

After function execution:
memory disappears.

---------------------------------------------------------
MEMORY ARRAY BEHAVIOR
---------------------------------------------------------

Memory array:
- temporary
- modifiable
- non-persistent

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Mutable memory arrays used for:

- temporary calculations
- sorting
- filtering
- aggregation
- batch processing
- intermediate transformations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Are memory changes intentional?
- Is storage accidentally expected to change?
- Can large memory operations cause DOS?
- Are loops scalable?
- Are copies handled safely?

=========================================================
*/
contract ModifyMemoryArrayVul {

    uint256[] public storedNumbers;

    function modifyInputArray(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256[] memory)
    {
        // Vulnerability:
        // No limit on user supplied array length

        for (uint256 i = 0; i < _numbers.length; i++) {
            _numbers[i] = _numbers[i] * 2;
        }

        return _numbers;
    }

    function storeValue(uint256 _value) public {
        storedNumbers.push(_value);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createAndModifyArray()

EVM ACTIONS:

1. Temporary memory allocated
2. Array created
3. Values inserted
4. tempArray[1] modified
5. Modified array returned
6. Memory destroyed after execution

---------------------------------------------------------

FINAL RETURNED ARRAY:

[1,999,3]

---------------------------------------------------------

IMPORTANT

No blockchain storage modified.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createAndModifyArray()

EXPECTED:
[1,999,3]

---------------------------------------------------------

STEP 3:
Call:
storedNumbers(0)

EXPECTED:
Error

Reason:
Nothing stored permanently.

---------------------------------------------------------

STEP 4:
Call:
modifyInputArray([5,6,7])

EXPECTED:
[777,6,7]

---------------------------------------------------------

STEP 5:
Call:
storeValue(100)

---------------------------------------------------------

STEP 6:
Call:
storedNumbers(0)

EXPECTED:
100

OBSERVE:
Storage persists.
Memory does not.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Modify zero values

Input:
[0,0,0]

EXPECTED:
[777,0,0]

---------------------------------------------------------

TEST:
Large arrays

OBSERVE:
Higher gas consumption

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Fresh memory created each execution

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

MEMORY ARRAYS ARE MUTABLE

You CAN change elements.

Example:

tempArray[1] = 999;

---------------------------------------------------------

HOWEVER:
Changes are temporary only.

---------------------------------------------------------

AFTER EXECUTION:
Memory cleared automatically.

=========================================================
MEMORY VS STORAGE MUTATION
=========================================================

---------------------------------------------------------
MEMORY MUTATION
---------------------------------------------------------

Temporary

Non-persistent

Cheap

---------------------------------------------------------
STORAGE MUTATION
---------------------------------------------------------

Permanent

Blockchain state updated

Expensive

=========================================================
IMPORTANT COPY BEHAVIOR
=========================================================

FUNCTION INPUT:

uint256[] memory _numbers

---------------------------------------------------------

This creates MEMORY COPY.

Modifying _numbers:
does NOT affect original external data.

=========================================================
GAS OBSERVATION
=========================================================

MEMORY OPERATIONS:
Cheaper than storage

---------------------------------------------------------

LARGE MEMORY ARRAYS:
Still expensive computationally

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Common Solidity bug.

Developers may incorrectly assume:
memory changes persist permanently.

---------------------------------------------------------
2. DOS RISK
---------------------------------------------------------

Large memory array operations may:
- consume excessive gas
- exceed block limits

---------------------------------------------------------
3. LOOP RISKS
---------------------------------------------------------

Nested loops on large memory arrays
can become dangerous.

---------------------------------------------------------
4. COPY ASSUMPTIONS
---------------------------------------------------------

Auditors verify:
whether function uses:
- reference
OR
- copy semantics

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker provides huge arrays.

Contract performs:
- heavy memory allocation
- large loops
- expensive modifications

Result:
DOS via gas exhaustion.

---------------------------------------------------------

ANOTHER RISK

Developer expects:
memory modifications persist.

Critical logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Double every element in memory array
2. Use loop for modification
3. Return updated array

BONUS:
Compare:
memory array vs storage array behavior

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory arrays are mutable
- Memory changes are temporary
- Memory cleared after execution
- Storage persists permanently
- Memory arrays useful for temporary processing
- Function inputs may become memory copies
- Memory operations cheaper than storage
- Large memory operations increase gas
- Memory/storage confusion causes bugs
- Auditors inspect temporary mutation carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Memory Array Processing in modifyInputArray()

Severity: Low because the vulnerability can lead to excessive
gas consumption and transaction failures, but does not result
in direct fund loss, unauthorized access, or permanent state
corruption.

Location:
Contract: ModifyMemoryArrayVul
Function: modifyInputArray()

Vulnerability Description:

The modifyInputArray() function accepts a user-supplied memory
array and iterates through every element without enforcing a
maximum array length.

An attacker can submit an extremely large array, forcing the
contract to perform excessive memory allocation and loop
iterations.

Although memory modifications are temporary and do not affect
storage, processing large arrays can consume significant gas
and potentially cause transaction failures.

Impact:

- Excessive gas consumption
- Transaction failures due to out-of-gas errors
- Reduced scalability
- Potential Denial-of-Service (DoS) conditions
- Increased computational overhead

Proof of Concept:

1. Deploy contract

2. Create a very large array
   (thousands of elements)

3. Call:

   modifyInputArray(hugeArray)

4. Contract loops through every element

5. Gas consumption increases significantly

6. Transaction may revert due to
   out-of-gas conditions

Root Cause:

The function processes a user-controlled memory array without
validating its length.

No upper bound exists on the number of elements that may be
supplied and processed within the loop.

Recommendation:

Restrict the maximum array length before processing the array.

Example:

uint256 public constant MAX_ARRAY_LENGTH = 100;

require(
    _numbers.length <= MAX_ARRAY_LENGTH,
    "Array too large"
);

This ensures predictable gas usage and prevents excessive
memory allocation and loop execution.

Patch Status:

Fixed.

The patched contract introduces:

- MAX_ARRAY_LENGTH constant
- Input validation using require()
- Controlled memory processing
- Predictable gas consumption

Patched Validation:

require(
    _numbers.length <= MAX_ARRAY_LENGTH,
    "Array too large"
);

This mitigation prevents attackers from submitting excessively
large arrays and reduces the risk of gas-exhaustion attacks.

*/

//Patched code
contract ModifyMemoryArray {

    uint256[] public storedNumbers;

    uint256 public constant MAX_ARRAY_LENGTH = 100;

    function modifyInputArray(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256[] memory)
    {
        require(
            _numbers.length <= MAX_ARRAY_LENGTH,
            "Array too large"
        );

        for (uint256 i = 0; i < _numbers.length; i++) {
            _numbers[i] = _numbers[i] * 2;
        }

        return _numbers;
    }

    function storeValue(uint256 _value) public {
        storedNumbers.push(_value);
    }
}