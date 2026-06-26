// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store many array values
CONCEPT: Storage gas cost
=========================================================

OBJECTIVE

- Learn why storage is expensive
- Understand array storage gas scaling
- Observe gas growth with many writes
- Think like auditor about storage-heavy logic

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every storage write costs gas.

---------------------------------------------------------

Writing MANY array values =
VERY expensive execution.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Storage is permanent blockchain data.

---------------------------------------------------------

Permanent storage is among the MOST
expensive EVM operations.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Storage-heavy contracts may become:

- too expensive
- DOS vulnerable
- inefficient
- unscalable

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Storage arrays appear in:

- NFT ownership
- staking lists
- governance records
- reward systems
- order books
- protocol accounting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- storage-heavy loops
- array growth
- scalability
- gas DOS risks
- unnecessary writes

=========================================================
STORAGE ARRAY CONTRACT
=========================================================
*/

contract StorageGasCost {

    /*
        LARGE STORAGE ARRAY
    */
    uint256[] public storedValues;

    /*
        TRACK TOTAL WRITES
    */
    uint256 public totalWrites;

    /*
        TRACK FINAL VALUE
    */
    uint256 public lastStoredValue;

    /*
    =====================================================
    STORE MANY VALUES
    =====================================================
    */

    function storeManyValues()
        external
    {

        /*
        =================================================
        LOOP 100 TIMES
        =================================================

        Every iteration performs:
        STORAGE WRITE.
        */

        for (
            uint256 i = 0;
            i < 100;
            i++
        ) {

            /*
            =============================================
            VERY EXPENSIVE OPERATION
            =============================================

            Push value into storage array.
            */

            storedValues.push(i);

            /*
                Another storage write.
            */
            totalWrites++;

            /*
                Another storage write.
            */
            lastStoredValue = i;
        }
    }

    /*
    =====================================================
    CHEAPER MEMORY VERSION
    =====================================================
    */

    function useMemoryArray()
        external
        pure
        returns (uint256[] memory)
    {

        /*
            Memory array exists temporarily.

            MUCH cheaper than storage.
        */
        uint256[] memory temp =
            new uint256[](100);

        /*
            Fill memory array.
        */
        for (
            uint256 i = 0;
            i < 100;
            i++
        ) {

            temp[i] = i;
        }

        /*
            Return temporary memory array.
        */
        return temp;
    }

    /*
    =====================================================
    GET ARRAY LENGTH
    =====================================================
    */

    function getLength()
        external
        view
        returns (uint256)
    {

        return storedValues.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy StorageGasCost

=========================================================
TRACE:
storeManyValues()
=========================================================

STEP 1:
Loop starts.

---------------------------------------------------------

i = 0

=========================================================
STEP 2
=========================================================

Storage write executes:

storedValues.push(0)

=========================================================
IMPORTANT
=========================================================

This writes permanently to blockchain storage.

---------------------------------------------------------

VERY expensive operation.

=========================================================
STEP 3
=========================================================

Another storage write:

totalWrites++

=========================================================
STEP 4
=========================================================

Another storage write:

lastStoredValue = 0

=========================================================
STEP 5
=========================================================

Loop repeats.

---------------------------------------------------------

i = 1

=========================================================
STEP 6
=========================================================

Again:

---------------------------------------------------------

storedValues.push(1)

---------------------------------------------------------

totalWrites++

---------------------------------------------------------

lastStoredValue = 1

=========================================================
LOOP CONTINUES
=========================================================

This repeats:

100 TIMES.

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
storedValues.length
---------------------------------------------------------

100

---------------------------------------------------------
totalWrites
---------------------------------------------------------

100

---------------------------------------------------------
lastStoredValue
---------------------------------------------------------

99

=========================================================
IMPORTANT GAS UNDERSTANDING
=========================================================

Gas usage becomes VERY HIGH because:

---------------------------------------------------------
100 STORAGE ARRAY WRITES
---------------------------------------------------------

occur.

=========================================================
MOST EXPENSIVE LINE
=========================================================

THIS:

storedValues.push(i)

=========================================================
WHY STORAGE IS EXPENSIVE
=========================================================

Blockchain storage is:

---------------------------------------------------------
PERMANENT
---------------------------------------------------------

and

---------------------------------------------------------
REPLICATED ACROSS ALL NODES
---------------------------------------------------------

=========================================================
MEMORY VERSION TRACE
=========================================================

CALL:
useMemoryArray()

=========================================================

STEP 1:
Memory array created.

---------------------------------------------------------

Temporary allocation only.

=========================================================
STEP 2
=========================================================

Values stored in memory.

---------------------------------------------------------

NOT permanent blockchain storage.

=========================================================
STEP 3
=========================================================

Function returns array.

---------------------------------------------------------

Memory automatically destroyed
after execution.

=========================================================
IMPORTANT COMPARISON
=========================================================

---------------------------------------------------------
STORAGE ARRAY
---------------------------------------------------------

- permanent
- expensive
- persists on blockchain

=========================================================

---------------------------------------------------------
MEMORY ARRAY
---------------------------------------------------------

- temporary
- cheaper
- destroyed after execution

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
storeManyValues()

---------------------------------------------------------

Observe:
HIGH gas usage

=========================================================
STEP 2
=========================================================

Check:
getLength()

EXPECTED:
100

=========================================================
TEST 2
=========================================================

Call:
useMemoryArray()

---------------------------------------------------------

Observe:
MUCH lower gas usage

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Storage growth increases:

---------------------------------------------------------
EXECUTION COST
---------------------------------------------------------

and

---------------------------------------------------------
SCALABILITY RISK
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED STORAGE GROWTH
---------------------------------------------------------

Arrays grow forever.

---------------------------------------------------------
2. STORAGE WRITES INSIDE LOOPS
---------------------------------------------------------

Huge gas consumption.

---------------------------------------------------------
3. GAS DOS
---------------------------------------------------------

Functions become uncallable.

---------------------------------------------------------
4. UNNECESSARY STORAGE
---------------------------------------------------------

Wasted blockchain resources.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- enlarge arrays
- force expensive writes
- trigger gas exhaustion
- DOS protocol execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Does storage grow infinitely?
- Are writes necessary?
- Can attacker force writes?
- Is loop bounded?
- Can gas exceed safe limits?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors analyze:

---------------------------------------------------------
STORAGE COMPLEXITY
---------------------------------------------------------

AND

---------------------------------------------------------
LONG-TERM SCALABILITY
---------------------------------------------------------

=========================================================
WHY STORAGE OPTIMIZATION MATTERS
=========================================================

Storage costs REAL ETH.

---------------------------------------------------------

Bad storage design =
expensive protocol.

=========================================================
BEST PRACTICES
=========================================================

- Minimize storage writes
- Prefer memory when possible
- Avoid large loops
- Batch operations carefully
- Limit array growth

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Store 1000 values
2. Compare gas usage
3. Remove unnecessary writes
4. Use struct arrays

BONUS:
Create gas-optimized batch storage.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage writes are expensive
- Arrays increase storage cost
- Permanent blockchain data costs gas
- Memory is cheaper than storage
- Large arrays create scalability risk
- Storage-heavy loops are dangerous
- Ethereum charges for permanent state
- Auditors inspect storage complexity
- Gas optimization is critical
- Unbounded storage growth is risky

=========================================================
*/
/*
Audit Report

Title: Excessive Storage Writes Inside Loop

Severity: Informational because the issue affects gas efficiency and scalability,
not the security or correctness of the contract.

Location:
Contract: StorageGasCost
Function: storeManyValues()

Vulnerability Description:
The storeManyValues() function performs multiple storage writes during each
iteration of a loop. Specifically, it executes:

- storedValues.push(i);
- totalWrites++;
- lastStoredValue = i;

Although the loop is bounded to 100 iterations and cannot be manipulated by an
attacker, repeated storage writes significantly increase gas consumption. In
particular, lastStoredValue is overwritten 100 times even though only the final
value is required.

Impact:
The contract remains secure, but execution becomes more expensive than
necessary.

Potential consequences include:

- Higher transaction fees
- Reduced gas efficiency
- Poor scalability if the loop size is increased in future versions
- Increased operational costs for users

Proof of Concept:

1. Deploy StorageGasCost.
2. Call:
      storeManyValues()
3. Observe that during each of the 100 iterations:
      - storedValues.push(i) writes to storage
      - totalWrites++ writes to storage
      - lastStoredValue = i writes to storage
4. After execution:
      storedValues.length = 100
      totalWrites = 100
      lastStoredValue = 99
5. Notice that lastStoredValue was written 100 times even though only the final
   value (99) is retained.

Root Cause:
The function performs unnecessary storage writes inside the loop.
The variable lastStoredValue is updated on every iteration despite only its
final value being needed after loop completion.

Recommendation:
Reduce storage writes by using local memory/stack variables during the loop and
perform a single storage write after the loop completes.

Example:

uint256 last;

for (uint256 i = 0; i < 100; i++) {
    storedValues.push(i);
    totalWrites++;
    last = i;
}

lastStoredValue = last;

This optimization lowers gas consumption while preserving the same behavior.

*/