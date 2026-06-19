// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return large memory array
CONCEPT: Memory allocation
=========================================================

OBJECTIVE

- Learn how large memory arrays are allocated
- Understand memory expansion costs
- Learn how returning large arrays affects gas
- Understand scalability risks in Solidity

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory arrays are allocated dynamically
during execution.

Larger arrays:
- require more memory
- consume more gas
- increase execution cost

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Returning large arrays can become expensive.

Reason:
EVM must:
- allocate memory
- store elements
- encode return data

---------------------------------------------------------
REAL-WORLD IMPORTANCE
---------------------------------------------------------

Large memory operations affect:

- scalability
- gas efficiency
- DOS resistance
- protocol usability

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large arrays appear in:

- DeFi protocols
- NFT collections
- staking systems
- governance snapshots
- batch operations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can arrays grow unbounded?
- Can functions become uncallable?
- Is gas exhaustion possible?
- Are loops scalable?
- Is pagination needed?

=========================================================
*/
contract LargeMemoryArrayVul {

    uint256[] public storedValues;

    function addValues(uint256 _count) public {

        for (uint256 i = 0; i < _count; i++) {

            storedValues.push(i);
        }
    }

    function returnLargeArray(uint256 _size)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tempArray =
            new uint256[](_size);

        for (uint256 i = 0; i < _size; i++) {

            tempArray[i] = i + 1;
        }

        return tempArray;
    }

    function copyStorageToMemory()
        public
        view
        returns (uint256[] memory)
    {
        return storedValues;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
returnLargeArray(5)

EVM ACTIONS:

1. Allocate memory for 5 elements
2. Create temporary array
3. Fill array using loop
4. Encode return data
5. Return memory array
6. Memory cleared after execution

---------------------------------------------------------

RETURNED ARRAY:

[1,2,3,4,5]

=========================================================

CALL:
returnLargeArray(1000)

OBSERVE:

- more memory allocation
- more loop iterations
- higher gas consumption
- larger return data

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
returnLargeArray(5)

EXPECTED:
[1,2,3,4,5]

---------------------------------------------------------

STEP 3:
Call:
returnLargeArray(50)

OBSERVE:
Higher execution cost

---------------------------------------------------------

STEP 4:
Call:
returnLargeArray(500)

OBSERVE:
Even higher gas usage

---------------------------------------------------------

STEP 5:
Call:
addValues(20)

---------------------------------------------------------

STEP 6:
Call:
copyStorageToMemory()

EXPECTED:
Returns all stored values

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
_size = 0

EXPECTED:
Empty array returned

---------------------------------------------------------

TEST:
Very large _size

OBSERVE:
Possible:
- high gas cost
- out-of-gas errors

---------------------------------------------------------

TEST:
Huge storage array copy

OBSERVE:
Function may become expensive/unusable

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

THIS LINE:

new uint256[](_size)

---------------------------------------------------------

ALLOCATES:
dynamic memory space.

---------------------------------------------------------

LARGER ARRAYS:
require more EVM memory expansion.

---------------------------------------------------------

VERY IMPORTANT

Memory is temporary:
cleared after execution.

=========================================================
MEMORY EXPANSION COST
=========================================================

EVM charges gas for:
- allocating memory
- expanding memory
- writing values
- encoding return data

---------------------------------------------------------

LARGE ARRAYS:
grow gas costs rapidly.

=========================================================
RETURN DATA COST
=========================================================

Returning large arrays also costs gas.

Reason:
EVM must ABI-encode:
every array element.

=========================================================
SCALABILITY RISK
=========================================================

UNBOUNDED ARRAYS ARE DANGEROUS.

Functions may become:
- too expensive
- uncallable
- DOS vulnerable

=========================================================
GAS OBSERVATION
=========================================================

SMALL ARRAY:
Cheap

---------------------------------------------------------

LARGE ARRAY:
Expensive

---------------------------------------------------------

VERY LARGE ARRAY:
Possible out-of-gas failure

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA GAS EXHAUSTION
---------------------------------------------------------

Huge arrays may:
- exceed block gas limit
- make function unusable

---------------------------------------------------------
2. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over attacker-controlled size
are dangerous.

---------------------------------------------------------
3. STORAGE-TO-MEMORY COPYING
---------------------------------------------------------

Copying massive storage arrays
can break scalability.

---------------------------------------------------------
4. PAGINATION REQUIREMENT
---------------------------------------------------------

Auditors often recommend:
pagination instead of returning everything.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker grows storage array massively.

Then calls:
copyStorageToMemory()

Result:
- excessive gas usage
- DOS condition
- function unusable

---------------------------------------------------------

REAL-WORLD ISSUE

Many protocols became uncallable
because arrays grew too large.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add pagination support
2. Return only partial array range
3. Avoid returning entire huge array

BONUS:
Implement:
(start, limit) logic

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory arrays allocate temporary memory
- Large arrays increase gas consumption
- Memory expansion costs gas
- Returning arrays requires ABI encoding
- Large return data becomes expensive
- Unbounded loops create scalability risks
- Storage-to-memory copying can be dangerous
- DOS via gas exhaustion is common
- Pagination improves scalability
- Auditors inspect array growth carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Loop and Large Memory Allocation Leading to Denial of Service

Severity: Medium because attacker-controlled inputs can cause excessive gas consumption
and make contract functions impractical or unusable.

Location:
Contract: LargeMemoryArray

Function:
- addValues(uint256 _count)
- returnLargeArray(uint256 _size)
- copyStorageToMemory()

Vulnerability Description:

The contract performs unbounded iterations and memory allocations based on
user-supplied parameters.

1. addValues() allows arbitrary _count values, causing the loop to execute
   an unbounded number of iterations.

2. returnLargeArray() allocates a memory array using an attacker-controlled
   _size parameter.

3. copyStorageToMemory() returns the entire storage array regardless of size,
   causing storage-to-memory copying costs to grow indefinitely.

As the array size increases, gas consumption increases significantly and
may eventually exceed practical execution limits.

Impact:

An attacker can intentionally use very large input values or continuously
grow the storedValues array.

Consequences include:

- Excessive gas consumption
- Out-of-gas transaction failures
- Reduced protocol scalability
- Denial of Service conditions
- Functions becoming unusable as data grows

Proof of Concept:

1. Deploy contract

2. Call:

    addValues(100000);

Result:
- Large storage growth
- Very high gas consumption

3. Call:

    returnLargeArray(100000);

Result:
- Massive memory allocation
- Potential out-of-gas failure

4. Call:

    copyStorageToMemory();

After storedValues becomes extremely large.

Result:
- Entire array copied into memory
- Excessive gas cost
- Function may become impractical to execute

Root Cause:

The contract lacks limits on user-controlled array sizes and loop iterations.

Examples:

addValues():

    for (uint256 i = 0; i < _count; i++) {
        storedValues.push(i);
    }

returnLargeArray():

    uint256[] memory tempArray =
        new uint256[](_size);

copyStorageToMemory():

    return storedValues;

No validation exists to restrict:

- batch size
- memory allocation size
- storage array retrieval size

Recommendation:

Implement upper bounds and pagination.

Example:

    require(
        _count <= MAX_BATCH,
        "Batch too large"
    );

    require(
        _size <= MAX_ARRAY_SIZE,
        "Array too large"
    );

Replace full array retrieval with paginated access:

    getValues(start, limit);

This ensures predictable gas consumption and improves scalability.

Patched Version Validation:

The patched contract mitigates the issue by:

- Limiting batch insertion size
- Limiting memory allocation size
- Implementing pagination
- Restricting page size

Result:

The Denial-of-Service and scalability risks associated with unbounded loops,
memory expansion, and full storage-array copying are successfully mitigated.
*/

//Patched code
contract LargeMemoryArrayPatched {

    uint256[] public storedValues;

    uint256 public constant MAX_BATCH = 100;
    uint256 public constant MAX_ARRAY_SIZE = 1000;
    uint256 public constant MAX_PAGE_SIZE = 100;

    function addValues(uint256 _count) public {

        require(
            _count <= MAX_BATCH,
            "Batch too large"
        );

        for (uint256 i = 0; i < _count; i++) {

            storedValues.push(i);
        }
    }

    function returnLargeArray(uint256 _size)
        public
        pure
        returns (uint256[] memory)
    {
        require(
            _size <= MAX_ARRAY_SIZE,
            "Array too large"
        );

        uint256[] memory tempArray =
            new uint256[](_size);

        for (uint256 i = 0; i < _size; i++) {

            tempArray[i] = i + 1;
        }

        return tempArray;
    }

    function getValues(
        uint256 start,
        uint256 limit
    )
        public
        view
        returns (uint256[] memory)
    {
        require(
            limit <= MAX_PAGE_SIZE,
            "Page too large"
        );

        require(
            start < storedValues.length ||
            storedValues.length == 0,
            "Invalid start"
        );

        if (storedValues.length == 0) {
            return new uint256[](0);
        }

        uint256 end = start + limit;

        if (end > storedValues.length) {
            end = storedValues.length;
        }

        uint256[] memory result =
            new uint256[](end - start);

        for (uint256 i = start; i < end; i++) {

            result[i - start] =
                storedValues[i];
        }

        return result;
    }
}