// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return memory variable
CONCEPT: Memory lifecycle
=========================================================

OBJECTIVE

- Learn how memory variables work in Solidity
- Understand memory lifecycle during execution
- Learn how memory variables are returned
- Understand difference between memory and storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory variables:
- are temporary
- exist only during function execution
- disappear after execution finishes

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Memory is used for:
- temporary data
- function arguments
- return values
- dynamic data handling

---------------------------------------------------------
MEMORY VS STORAGE
---------------------------------------------------------

MEMORY:
- temporary
- cheaper than storage
- cleared after execution

STORAGE:
- permanent
- expensive
- persists on blockchain

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory commonly used for:

- strings
- arrays
- structs
- temporary calculations
- returned data

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is memory used correctly?
- Is storage accidentally modified?
- Are memory copies intentional?
- Are references handled safely?
- Is unnecessary storage avoided?

=========================================================
*/
contract MemoryLifecycleVul {

    string public storedName = "Blockchain";

    function createMemoryVariable()
        public
        pure
        returns (uint256)
    {
        uint256 localValue = 100;

        return localValue;
    }

    function returnMemoryString(
        uint256 size
    )
        public
        pure
        returns (uint256[] memory)
    {
        // Vulnerability:
        // User controls memory allocation size.
        uint256[] memory hugeArray = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            hugeArray[i] = i;
        }

        return hugeArray;
    }

    function copyStorageToMemory()
        public
        view
        returns (string memory)
    {
        string memory localCopy = storedName;

        return localCopy;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createMemoryVariable()

EVM ACTIONS:

1. Function execution starts
2. localValue created temporarily
3. localValue stored in stack/memory
4. Value returned
5. localValue destroyed after execution

---------------------------------------------------------

IMPORTANT:
Nothing stored permanently.

---------------------------------------------------------

CALL:
returnMemoryString()

EVM ACTIONS:

1. tempName allocated in memory
2. String stored temporarily
3. Memory data returned
4. Memory cleared after execution

---------------------------------------------------------

CALL:
copyStorageToMemory()

EVM ACTIONS:

1. Read storedName from storage
2. Create temporary memory copy
3. Return memory copy
4. Memory destroyed after execution

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createMemoryVariable()

EXPECTED:
100

---------------------------------------------------------

STEP 3:
Call:
returnMemoryString()

EXPECTED:
"Solidity"

---------------------------------------------------------

STEP 4:
Call:
copyStorageToMemory()

EXPECTED:
"Blockchain"

---------------------------------------------------------

STEP 5:
Check:
storedName()

EXPECTED:
"Blockchain"

OBSERVE:
Storage unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Repeated function calls

EXPECTED:
Memory recreated every execution

---------------------------------------------------------

TEST:
Return empty string

Modify code:
string memory tempName = "";

EXPECTED:
Returns empty string successfully

---------------------------------------------------------

TEST:
Large strings

OBSERVE:
More memory allocation
= higher gas usage

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

MEMORY LIFECYCLE

1. Memory allocated during execution
2. Temporary data stored
3. Function returns data
4. Memory cleared after execution

---------------------------------------------------------

VERY IMPORTANT

Memory does NOT persist on blockchain.

---------------------------------------------------------

THIS IS TEMPORARY:

string memory tempName;

---------------------------------------------------------

THIS IS PERSISTENT:

string public storedName;

=========================================================
MEMORY COPY BEHAVIOR
=========================================================

EXAMPLE:

string memory localCopy = storedName;

---------------------------------------------------------

WHAT HAPPENS?

1. storedName read from storage
2. Data copied into memory
3. localCopy becomes independent copy

---------------------------------------------------------

IMPORTANT

Changing localCopy does NOT modify storage.

=========================================================
GAS OBSERVATION
=========================================================

MEMORY:
Cheaper than storage

---------------------------------------------------------

STORAGE:
Expensive because blockchain state changes

---------------------------------------------------------

Returning memory data still consumes:
- execution gas
- memory expansion cost

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Common Solidity bug source.

Developers may think:
memory changes affect storage.

They do NOT.

---------------------------------------------------------
2. ACCIDENTAL STORAGE COPIES
---------------------------------------------------------

Auditors inspect:
- reference behavior
- unintended mutations
- data copying logic

---------------------------------------------------------
3. LARGE MEMORY ALLOCATION
---------------------------------------------------------

Huge arrays/strings may:
- consume excessive gas
- create DOS vectors

---------------------------------------------------------
4. RETURN DATA RISKS
---------------------------------------------------------

Returning excessive data may:
- exceed gas limits
- increase execution costs

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker provides huge input arrays/strings.

Result:
- excessive memory allocation
- increased gas consumption
- possible DOS behavior

---------------------------------------------------------

ANOTHER RISK

Developer expects memory update
to persist permanently.

Logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Create memory array
2. Store values inside it
3. Return array from function

BONUS:
Compare memory array vs storage array.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory variables are temporary
- Memory cleared after execution
- Storage persists permanently
- Dynamic types commonly use memory
- Returning memory data is common
- Storage-to-memory creates copy
- Memory updates do not affect storage
- Memory cheaper than storage
- Large memory usage increases gas
- Auditors inspect memory behavior carefully

=========================================================
*/
/*
Audit Report

Title: Unbounded Memory Allocation in returnMemoryString()

Severity: Low because the vulnerability can cause excessive gas
consumption and transaction failures but does not directly lead
to fund loss or unauthorized state modification.

Location:
Contract: MemoryLifecycleVul
Function: returnMemoryString()

Vulnerability Description:

The returnMemoryString() function allows users to specify any
array size through the size parameter.

The function allocates memory directly using:

uint256[] memory hugeArray = new uint256[](size);

Because no upper limit exists, an attacker can request an
extremely large array, forcing excessive memory expansion
inside the EVM.

Impact:

- Excessive gas consumption
- Transaction failures
- Resource exhaustion
- Potential Denial-of-Service (DoS) conditions
- Increased execution costs for callers

Proof of Concept:

1. Deploy contract

2. Attacker calls:

   returnMemoryString(1000000)

3. Contract attempts to allocate a massive array

4. Gas usage increases dramatically

5. Transaction may revert due to out-of-gas conditions

Root Cause:

The function performs memory allocation using a
user-controlled parameter without validation.

No require() statement restricts the maximum
size of the allocated array.

Recommendation:

Restrict memory allocation by enforcing a maximum
array size before creating the array.

Example:

uint256 public constant MAX_ARRAY_SIZE = 100;

require(
    size <= MAX_ARRAY_SIZE,
    "Array too large"
);

This ensures predictable gas consumption and
prevents excessive memory allocation attacks.

*/
//Patched code
contract MemoryLifecycle {

    string public storedName = "Blockchain";

    uint256 public constant MAX_ARRAY_SIZE = 100;

    function createMemoryVariable()
        public
        pure
        returns (uint256)
    {
        uint256 localValue = 100;

        return localValue;
    }

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

    function copyStorageToMemory()
        public
        view
        returns (string memory)
    {
        string memory localCopy = storedName;

        return localCopy;
    }
}