// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Increase loop to 1000 iterations
CONCEPT: Gas scaling
=========================================================

OBJECTIVE

- Learn how gas scales with loop size
- Understand expensive execution patterns
- Observe storage-write gas costs
- Think like auditor about scalability risk

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

More loop iterations =
more gas consumption.

---------------------------------------------------------

Gas usage scales approximately:

LINEARLY

with iteration count.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

1000 iterations consume MUCH more gas
than 10 iterations.

---------------------------------------------------------

Especially when loop contains:

- storage writes
- external calls
- memory expansion

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Large loops can make contracts:

- unusable
- DOS vulnerable
- too expensive to execute

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Large loops appear in:

- reward systems
- NFT airdrops
- mass payouts
- governance processing
- staking calculations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- scalability
- gas complexity
- unbounded iteration
- storage-heavy loops
- DOS possibilities

=========================================================
GAS-SCALING CONTRACT
=========================================================
*/

contract GasScalingLoop {

    /*
        STORE VALUES
    */
    uint256[] public values;

    /*
        TRACK ITERATIONS
    */
    uint256 public totalIterations;

    /*
        STORE FINAL SUM
    */
    uint256 public finalSum;

    /*
    =====================================================
    LOOP 1000 TIMES
    =====================================================
    */

    function loop1000()
        external
    {

        /*
            Temporary local variable.

            Stored in:
            stack/memory

            NOT persistent storage.
        */
        uint256 sum = 0;

        /*
        =================================================
        LARGE LOOP
        =================================================

        Executes:
        1000 iterations
        */

        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {

            /*
            =============================================
            GAS COST OCCURS HERE
            =============================================

            Every iteration performs:

            - comparison
            - arithmetic
            - increment
            - storage write
            */

            sum += i;

            /*
                VERY EXPENSIVE.

                Storage write every iteration.
            */
            values.push(i);

            /*
                Another storage write.
            */
            totalIterations++;
        }

        /*
            Final storage write.
        */
        finalSum = sum;
    }

    /*
    =====================================================
    CHEAPER LOOP
    =====================================================

    No storage writes inside loop.
    */

    function optimizedLoop1000()
        external
    {

        /*
            Temporary local variable.
        */
        uint256 sum = 0;

        /*
            Loop 1000 times.
        */
        for (
            uint256 i = 0;
            i < 1000;
            i++
        ) {

            /*
                ONLY arithmetic.

                Much cheaper than storage writes.
            */
            sum += i;
        }

        /*
            Single storage write at end.
        */
        finalSum = sum;
    }

    /*
    =====================================================
    CHECK ARRAY LENGTH
    =====================================================
    */

    function getArrayLength()
        external
        view
        returns (uint256)
    {

        return values.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy GasScalingLoop

=========================================================
TRACE:
loop1000()
=========================================================

STEP 1:
Function starts.

---------------------------------------------------------

sum = 0

=========================================================
STEP 2
=========================================================

Loop initializes:

i = 0

=========================================================
STEP 3
=========================================================

Condition checked:

i < 1000

---------------------------------------------------------

TRUE

=========================================================
STEP 4
=========================================================

Loop body executes.

---------------------------------------------------------

sum += i

---------------------------------------------------------

values.push(i)

---------------------------------------------------------

totalIterations++

=========================================================
IMPORTANT
=========================================================

Every iteration performs:

---------------------------------------------------------
COMPUTATION
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE WRITES
---------------------------------------------------------

=========================================================
LOOP CONTINUES
=========================================================

Iterations:

---------------------------------------------------------
0
---------------------------------------------------------

1

---------------------------------------------------------

2

---------------------------------------------------------

...

---------------------------------------------------------

999

=========================================================
FINAL ITERATION
=========================================================

After:

i = 999

---------------------------------------------------------

i++

---------------------------------------------------------

i = 1000

=========================================================
LOOP EXIT
=========================================================

Condition checked:

1000 < 1000

---------------------------------------------------------

FALSE

---------------------------------------------------------

Loop stops.

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
totalIterations
---------------------------------------------------------

1000

---------------------------------------------------------
values.length
---------------------------------------------------------

1000

---------------------------------------------------------
finalSum
---------------------------------------------------------

499500

=========================================================
WHY 499500?
=========================================================

Formula:

n(n-1)/2

---------------------------------------------------------

1000 * 999 / 2

---------------------------------------------------------

499500

=========================================================
IMPORTANT GAS UNDERSTANDING
=========================================================

Gas usage becomes VERY high because:

---------------------------------------------------------
1000 STORAGE WRITES
---------------------------------------------------------

occur.

=========================================================
MOST EXPENSIVE OPERATION
=========================================================

THIS LINE:

values.push(i)

---------------------------------------------------------

Storage writes are among
the MOST expensive EVM operations.

=========================================================
COMPARE FUNCTIONS
=========================================================

---------------------------------------------------------
loop1000()
---------------------------------------------------------

VERY expensive

---------------------------------------------------------

Reason:
storage writes inside loop

=========================================================

---------------------------------------------------------
optimizedLoop1000()
---------------------------------------------------------

MUCH cheaper

---------------------------------------------------------

Reason:
only one storage write

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
loop1000()

---------------------------------------------------------

Observe:
HIGH gas usage

=========================================================
STEP 2
=========================================================

Check:
getArrayLength()

EXPECTED:
1000

---------------------------------------------------------

Check:
totalIterations()

EXPECTED:
1000

=========================================================
TEST 2
=========================================================

Call:
optimizedLoop1000()

---------------------------------------------------------

Observe:
MUCH lower gas usage

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Gas scales with:

---------------------------------------------------------
WORK PER ITERATION
---------------------------------------------------------

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Loops become dangerous when:

---------------------------------------------------------
ITERATION COUNT GROWS
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

User-controlled iteration count.

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

Massive gas explosion.

---------------------------------------------------------
3. GAS DOS
---------------------------------------------------------

Function becomes impossible to execute.

---------------------------------------------------------
4. EXTERNAL CALLS INSIDE LOOP
---------------------------------------------------------

Extremely dangerous pattern.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- enlarge arrays
- force massive loops
- increase gas costs
- DOS protocol execution

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors estimate:

---------------------------------------------------------
TIME COMPLEXITY
---------------------------------------------------------

AND

---------------------------------------------------------
GAS COMPLEXITY
---------------------------------------------------------

=========================================================
BIG-O THINKING
=========================================================

This loop complexity:

---------------------------------------------------------
O(n)
---------------------------------------------------------

Gas grows linearly with n.

=========================================================
WHY THIS MATTERS IN ETHEREUM
=========================================================

Ethereum has:

---------------------------------------------------------
BLOCK GAS LIMITS
---------------------------------------------------------

Too much execution =
transaction failure.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is loop bounded?
- Can attacker increase n?
- Are storage writes inside loop?
- Is function scalable?
- Could execution exceed gas limits?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Loop 10,000 times
2. Measure gas usage
3. Remove storage writes
4. Add external call inside loop

BONUS:
Create batch-processing design.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Gas scales with iteration count
- Storage writes are very expensive
- Large loops may DOS contracts
- O(n) execution impacts scalability
- Ethereum has gas limits
- Unbounded loops are dangerous
- Storage-heavy loops are risky
- Gas optimization matters heavily
- Auditors inspect scalability carefully
- Large loops create security risks

=========================================================
*/
/*
Audit Report

Title: No Security Vulnerability Identified in loop1000()

Severity: Informational

Location:
Contract: GasScalingLoop
Function: loop1000()

Vulnerability Description:

No exploitable security vulnerability was identified in the loop1000() function.

The function executes a fixed-size loop with exactly 1000 iterations.
Although the function performs storage writes during each iteration,
the number of iterations is hardcoded and cannot be influenced by
external users.

As a result, the gas cost is predictable and cannot be manipulated
by an attacker to perform a denial-of-service (DoS) attack.

The optimizedLoop1000() function demonstrates a more gas-efficient
implementation by avoiding storage writes inside the loop.

Impact:

No security impact.

The function cannot be abused to:

- increase the number of iterations
- exhaust the block gas limit through user input
- trigger a denial-of-service attack
- manipulate protocol execution

The only impact is higher gas consumption compared to the optimized
implementation, which is a performance consideration rather than a
security issue.

Proof of Concept:

1. Deploy the contract.
2. Call loop1000().
3. Observe:
   - totalIterations = 1000
   - values.length = 1000
   - finalSum = 499500
4. Transaction completes successfully with predictable gas usage.
5. Call optimizedLoop1000() and observe significantly lower gas
   consumption because only one storage write occurs after the loop.

Root Cause:

No vulnerability exists.

The loop has a fixed upper bound of 1000 iterations, preventing
unbounded execution and ensuring predictable gas consumption.

The storage writes inside the loop increase gas usage but do not
introduce an exploitable security weakness.

Recommendation:

No security patch is required.

For better gas efficiency, minimize storage writes inside loops by:

- performing calculations in memory
- updating storage only once after the loop
- batching large operations when processing many items

If future versions allow user-controlled iteration counts or iterate
over dynamically growing arrays, enforce a maximum limit or use
batch processing to prevent gas-related denial-of-service risks.

*/