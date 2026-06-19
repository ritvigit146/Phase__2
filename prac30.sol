// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare calldata vs memory
CONCEPT: Gas + mutability
=========================================================

OBJECTIVE

- Learn difference between calldata and memory
- Understand gas efficiency differences
- Learn mutability behavior
- Understand when to use calldata vs memory

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

CALLDATA:
- external input area
- read-only
- cheaper
- avoids copying

MEMORY:
- temporary execution area
- mutable
- more expensive
- requires allocation/copying

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Choosing correct data location:
- affects gas usage
- affects mutability
- affects protocol efficiency

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Gas optimization is critical in:

- DeFi protocols
- routers
- NFT systems
- governance contracts
- multicall architectures

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

CALldata commonly used for:
- external read-only inputs

Memory commonly used for:
- temporary modifications
- internal processing

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata preferable?
- Are unnecessary copies created?
- Are developers misunderstanding mutability?
- Can large copies create DOS?
- Is gas optimized properly?

=========================================================
*/
contract CalldataVsMemoryVulnerable {

    uint256[] public storedValues;

    function useCalldata(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function useMemory(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    // Vulnerable:
    // 1. No check for empty array
    // 2. No limit on array size
    function modifyMemory(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tempArray = _numbers;

        tempArray[0] = 999;

        return tempArray;
    }

    // Vulnerable:
    // Unbounded loop over attacker-controlled array
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
useCalldata([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Loop reads directly from calldata
3. No memory copy created
4. Result returned
5. Calldata discarded

---------------------------------------------------------

GAS:
Cheaper

=========================================================

CALL:
modifyMemory([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Full copy created in memory
3. Memory array modified
4. Modified copy returned
5. Memory destroyed

---------------------------------------------------------

GAS:
More expensive than calldata-only read

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
useCalldata([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 3:
Call:
useMemory([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 4:
Compare gas usage

OBSERVE:
calldata cheaper than memory

---------------------------------------------------------

STEP 5:
Call:
modifyMemory([5,6,7])

EXPECTED:
[999,6,7]

---------------------------------------------------------

STEP 6:
Observe:
Original calldata unchanged

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
0

---------------------------------------------------------

TEST:
Pass huge array

OBSERVE:
Higher gas usage

---------------------------------------------------------

TEST:
Modify calldata directly

EXPECTED:
Compiler error

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA:
- temporary
- immutable
- external-input optimized

---------------------------------------------------------

BEST FOR:
Read-only external inputs.

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

MEMORY:
- temporary
- mutable
- supports modifications

---------------------------------------------------------

BEST FOR:
Temporary processing and mutations.

=========================================================
CALLDATA VS MEMORY COMPARISON
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Read-only

Cheaper

No automatic copy

Cannot modify

External functions only

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Mutable

More expensive

Requires allocation

Can modify

Used internally too

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
More gas efficient

---------------------------------------------------------

Reason:
Avoids memory allocation/copying.

---------------------------------------------------------

MEMORY:
More expensive due to:
- allocation
- copying
- expansion

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. UNNECESSARY MEMORY COPIES
---------------------------------------------------------

Common gas inefficiency.

Auditors recommend:
calldata where possible.

---------------------------------------------------------
2. DOS VIA LARGE ARRAYS
---------------------------------------------------------

Huge arrays may:
- exhaust gas
- break loops
- create scalability issues

---------------------------------------------------------
3. MUTABILITY CONFUSION
---------------------------------------------------------

Developers may incorrectly assume:
calldata can be modified.

---------------------------------------------------------
4. LOOP RISKS
---------------------------------------------------------

Attacker-controlled arrays
must be bounded carefully.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge array.

Contract unnecessarily copies:
calldata -> memory.

Result:
- wasted gas
- DOS condition
- inefficient execution

---------------------------------------------------------

ANOTHER RISK

Developer expects:
calldata modification.

Logic silently fails.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata string array
2. Copy into memory
3. Modify one element safely
4. Return updated memory array

BONUS:
Measure gas differences in Remix.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata is read-only
- Memory is mutable
- Calldata cheaper than memory
- Memory requires allocation
- Copying arrays costs gas
- External inputs arrive via calldata
- Memory useful for temporary modifications
- Large arrays create DOS risks
- Gas optimization matters heavily
- Auditors inspect data-location efficiency carefully

=========================================================
*/
//Patched code
contract CalldataVsMemoryPatched {

    uint256[] public storedValues;

    uint256 public constant MAX_ARRAY_SIZE = 100;

    function useCalldata(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function useMemory(
        uint256[] memory _numbers
    )
        public
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function modifyMemory(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {
        require(_numbers.length > 0, "Empty array");
        require(
            _numbers.length <= MAX_ARRAY_SIZE,
            "Array too large"
        );

        uint256[] memory tempArray = _numbers;

        tempArray[0] = 999;

        return tempArray;
    }

    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {
        require(
            _numbers.length <= MAX_ARRAY_SIZE,
            "Array too large"
        );

        for (uint256 i = 0; i < _numbers.length; i++) {
            storedValues.push(_numbers[i]);
        }
    }
}