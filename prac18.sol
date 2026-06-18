// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Create memory array
CONCEPT: Temporary arrays
=========================================================

OBJECTIVE

- Learn how memory arrays work in Solidity
- Understand temporary array allocation
- Learn difference between memory arrays and storage arrays
- Understand memory array lifecycle

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory arrays:
- are temporary
- exist only during execution
- disappear after function finishes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Memory arrays do NOT persist
on blockchain storage.

They are useful for:
- temporary calculations
- returning data
- processing values
- intermediate logic

---------------------------------------------------------
MEMORY ARRAY VS STORAGE ARRAY
---------------------------------------------------------

MEMORY ARRAY:
- temporary
- cheaper
- disappears after execution

STORAGE ARRAY:
- permanent
- expensive
- persists on blockchain

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory arrays used in:

- batch calculations
- temporary filtering
- returning lists
- internal processing
- aggregation logic

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is memory used safely?
- Is storage accidentally modified?
- Can large arrays cause DOS?
- Are loops scalable?
- Is memory allocation controlled?

=========================================================
*/
contract MemoryArrayVul {

    uint256[] public storedNumbers;

    function createMemoryArray(
        uint256 size
    )
        public
        pure
        returns (uint256[] memory)
    {
        // Vulnerability:
        // User controls memory allocation size
        uint256[] memory tempArray =
            new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            tempArray[i] = i + 1;
        }

        return tempArray;
    }

    function calculateSquares(
        uint256 _number
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory squares =
            new uint256[](3);

        squares[0] = _number;
        squares[1] = _number * _number;
        squares[2] = _number * _number * _number;

        return squares;
    }

    function storeValue(uint256 _value)
        public
    {
        storedNumbers.push(_value);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createMemoryArray()

EVM ACTIONS:

1. Memory allocated temporarily
2. Array size = 3 created
3. Values inserted
4. Array returned
5. Memory cleared after execution

---------------------------------------------------------

IMPORTANT

tempArray does NOT persist permanently.

---------------------------------------------------------

CALL:
calculateSquares(2)

MEMORY ARRAY CONTENT:

[2,4,8]

---------------------------------------------------------

AFTER EXECUTION

Memory array destroyed automatically.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createMemoryArray()

EXPECTED:
[10,20,30]

---------------------------------------------------------

STEP 3:
Call:
calculateSquares(2)

EXPECTED:
[2,4,8]

---------------------------------------------------------

STEP 4:
Call:
storedNumbers(0)

EXPECTED:
Error

Reason:
Nothing stored permanently yet.

---------------------------------------------------------

STEP 5:
Call:
storeValue(999)

---------------------------------------------------------

STEP 6:
Call:
storedNumbers(0)

EXPECTED:
999

OBSERVE:
Storage array persists.
Memory array does not.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Use zero values

calculateSquares(0)

EXPECTED:
[0,0,0]

---------------------------------------------------------

TEST:
Use large values

EXPECTED:
Solidity ^0.8.x overflow protection applies

---------------------------------------------------------

TEST:
Repeated calls

OBSERVE:
Fresh memory array created each execution

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

THIS CREATES MEMORY ARRAY:

new uint256[](3)

---------------------------------------------------------

ARRAY EXISTS ONLY:
during function execution.

---------------------------------------------------------

AFTER FUNCTION ENDS:
memory cleared automatically.

---------------------------------------------------------

VERY IMPORTANT

Memory arrays:
- cannot use push()
- require fixed size during creation

=========================================================
MEMORY ARRAY LIMITATION
=========================================================

THIS WORKS:

uint256[] memory arr = new uint256[](3);

---------------------------------------------------------

THIS FAILS:

arr.push(10);

Reason:
Memory arrays have fixed size.

=========================================================
MEMORY VS STORAGE ARRAY
=========================================================

---------------------------------------------------------
MEMORY ARRAY
---------------------------------------------------------

Temporary

Destroyed after execution

Cheaper

---------------------------------------------------------
STORAGE ARRAY
---------------------------------------------------------

Persistent

Stored on blockchain

Expensive

=========================================================
GAS OBSERVATION
=========================================================

MEMORY:
Cheaper than storage

---------------------------------------------------------

LARGE MEMORY ARRAYS:
Still increase gas consumption

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY DOS RISK
---------------------------------------------------------

Huge memory allocations may:
- consume excessive gas
- exceed block gas limits

---------------------------------------------------------
2. LOOP SCALABILITY
---------------------------------------------------------

Large memory arrays inside loops
can become dangerous.

---------------------------------------------------------
3. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Developers may incorrectly assume:
memory persists permanently.

---------------------------------------------------------
4. UNBOUNDED INPUTS
---------------------------------------------------------

Attacker-controlled array sizes
can create denial-of-service vectors.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker supplies huge input size.

Contract allocates massive memory array.

Result:
- excessive gas usage
- transaction failure
- DOS condition

---------------------------------------------------------

REAL-WORLD RISK

Improper array processing has caused:
- gas exhaustion
- uncallable functions
- scalability failures

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create memory array of size 5
2. Fill array using loop
3. Return all multiplied values

BONUS:
Compare gas between:
memory arrays vs storage arrays

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory arrays are temporary
- Memory cleared after execution
- Memory arrays require fixed size
- Memory arrays cannot use push()
- Storage arrays persist permanently
- Memory cheaper than storage
- Large memory arrays increase gas
- Dynamic data often returned from memory
- Unbounded memory allocation can be dangerous
- Auditors inspect memory scalability carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Memory Allocation in createMemoryArray()

Severity: Low because the issue can lead to excessive gas
consumption and transaction failures, but it does not
allow theft of funds or unauthorized state changes.

Location:
Contract: MemoryArrayVul
Function: createMemoryArray(uint256 size)

Vulnerability Description:

The createMemoryArray() function accepts a user-controlled
size parameter and directly uses it to allocate a memory array.

Example:

uint256[] memory tempArray = new uint256[](size);

Since there is no validation on size, an attacker can
request an extremely large array causing excessive memory
expansion inside the EVM.

Impact:

- Excessive gas consumption
- Transaction failure due to out-of-gas
- Resource exhaustion
- Potential Denial-of-Service (DoS)
- Reduced scalability of the contract

Proof of Concept:

1. Deploy contract

2. Attacker calls:

   createMemoryArray(1000000)

3. Contract attempts to allocate a massive
   memory array.

4. Memory expansion cost increases significantly.

5. Transaction may consume all available gas
   and revert.

Root Cause:

The function allocates memory using a
user-supplied size parameter without enforcing
a maximum limit.

No validation exists to prevent excessive
memory allocation.

Recommendation:

Restrict the maximum array size before
allocating memory.

Example:

uint256 public constant MAX_ARRAY_SIZE = 100;

require(
    size <= MAX_ARRAY_SIZE,
    "Array too large"
);

This ensures predictable memory usage and
prevents excessive gas consumption caused
by oversized arrays.

*/

//Patched code
contract MemoryArray {

    uint256[] public storedNumbers;

    uint256 public constant MAX_ARRAY_SIZE = 100;

    function createMemoryArray(
        uint256 size
    )
        public
        pure
        returns (uint256[] memory)
    {
        require(
            size <= MAX_ARRAY_SIZE,
            "Array too large"
        );

        uint256[] memory tempArray =
            new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            tempArray[i] = i + 1;
        }

        return tempArray;
    }

    function calculateSquares(
        uint256 _number
    )
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory squares =
            new uint256[](3);

        squares[0] = _number;
        squares[1] = _number * _number;
        squares[2] = _number * _number * _number;

        return squares;
    }

    function storeValue(uint256 _value)
        public
    {
        storedNumbers.push(_value);
    }
}