// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use repeated storage writes
CONCEPT: Expensive operations
=========================================================

OBJECTIVE

- Understand cost of repeated storage updates
- See how gas scales with state writes
- Learn why storage-heavy loops are dangerous
- Think like auditor about optimization risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every storage write costs gas.

---------------------------------------------------------

Repeated storage writes inside loops:
become VERY expensive quickly.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Storage writes:

- modify blockchain state
- are permanently stored
- require high gas

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Repeated writes can cause:

- high transaction cost
- out-of-gas failure
- denial of service
- unscalable contracts

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Repeated writes appear in:

- reward updates
- counters
- staking systems
- voting systems
- accounting updates

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- write frequency
- loop-based storage updates
- redundant state changes
- gas inefficiencies
- optimization opportunities

=========================================================
EXPENSIVE STORAGE CONTRACT
=========================================================
*/
contract RepeatedStorageWritesVul {

    uint256 public counter;
    uint256 public lastValue;

    uint256[] public history;

    /*
        VULNERABLE FUNCTION

        Anyone can supply an arbitrarily
        large value for n.
    */
    function heavyWrites(uint256 n) external {

        for (uint256 i = 0; i < n; i++) {

            /*
                Storage write #1
            */
            counter++;

            /*
                Storage write #2
            */
            lastValue = i;

            /*
                Storage write #3
            */
            history.push(i);
        }
    }

    function getHistoryLength()
        external
        view
        returns (uint256)
    {
        return history.length;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy RepeatedStorageWrites

=========================================================
TRACE:
heavyWrites(n)
=========================================================

INPUT:
n = 100

=========================================================
STEP 2
=========================================================

Loop starts:

i = 0

=========================================================
STEP 3
=========================================================

STORAGE WRITE #1:

counter++

=========================================================
STEP 4
=========================================================

STORAGE WRITE #2:

lastValue = 0

=========================================================
STEP 5
=========================================================

STORAGE WRITE #3:

history.push(0)

=========================================================
STEP 6
=========================================================

Repeat for i = 1 ... 99

=========================================================
IMPORTANT OBSERVATION
=========================================================

Each iteration performs:

---------------------------------------------------------
3 STORAGE WRITES
---------------------------------------------------------

Total:

100 × 3 = 300 writes

=========================================================
GAS IMPACT
=========================================================

This becomes VERY expensive.

---------------------------------------------------------

May lead to:

- high transaction cost
- gas limit issues
- execution failure

=========================================================
OPTIMIZED FLOW
=========================================================

CALL:
optimizedWrites(100)

=========================================================

STEP 1:
All computation happens in memory.

=========================================================
STEP 2
=========================================================

Only 2 final storage writes:

---------------------------------------------------------
counter = tempCounter
lastValue = tempValue

=========================================================
STEP 3
=========================================================

history updated in batch style.

=========================================================
IMPORTANT RESULT
=========================================================

Same outcome,
MUCH lower gas cost.

=========================================================
WHY THIS MATTERS
=========================================================

Storage writes are the MOST expensive
EVM operation.

---------------------------------------------------------

Reducing them improves scalability.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
heavyWrites(100)

---------------------------------------------------------

Observe:
HIGH gas usage

=========================================================
TEST 2
=========================================================

Call:
optimizedWrites(100)

---------------------------------------------------------

Observe:
lower gas usage

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Repeated storage writes cause:

---------------------------------------------------------
GAS EXPLOSION
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. LOOPED STORAGE WRITES
---------------------------------------------------------

very expensive pattern

---------------------------------------------------------
2. UNNECESSARY STATE UPDATES
---------------------------------------------------------

wasted gas

---------------------------------------------------------
3. USER CONTROLLED n
---------------------------------------------------------

can trigger DOS

---------------------------------------------------------
4. SCALABILITY FAILURE
---------------------------------------------------------

contract becomes unusable

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- increase n
- force heavy writes
- trigger gas exhaustion
- block execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors check:

- number of storage writes per call
- loop complexity
- worst-case gas cost
- user-controlled input size

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors calculate:

---------------------------------------------------------
writes_per_iteration × max_iterations
---------------------------------------------------------

to estimate risk.

=========================================================
BEST PRACTICES
=========================================================

- Minimize storage writes
- Batch updates
- Use memory for intermediate data
- Avoid per-iteration state changes
- Validate input size

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Limit n to 50
2. Compare gas usage
3. Add event logging instead of storage
4. Remove history array writes

BONUS:
Create event-based accounting system.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage writes are expensive
- Repeated writes increase gas linearly
- Loops with state changes are dangerous
- Memory is cheaper than storage
- Batch updates improve efficiency
- User-controlled loops can cause DOS
- Gas optimization is critical
- Auditors analyze write frequency
- Scalability depends on storage design
- Efficient state management is essential

=========================================================
*/
/*
Audit Report

Title: Unbounded Storage Writes Can Lead to Out-of-Gas Denial of Service

Severity: Medium because an unbounded user-controlled loop performs repeated
storage writes, which can consume excessive gas and cause the transaction
to revert, making the function unusable for large inputs.

Location:
Contract: RepeatedStorageWritesVul
Function: heavyWrites()

Vulnerability Description:

The heavyWrites() function accepts a user-controlled parameter n and
performs three storage write operations during every loop iteration.

Specifically, each iteration:
- increments the counter variable
- updates the lastValue variable
- appends a new element to the history array

Since there is no upper limit on n, a caller can request an extremely
large number of iterations. As the number of storage writes increases,
gas consumption grows linearly and may eventually exceed the block gas
limit, causing the transaction to fail with an Out-of-Gas (OOG) error.

Impact:

An attacker or any user can supply a very large value for n.

This may result in:

- excessive gas consumption
- Out-of-Gas transaction failures
- Denial of Service (DoS) for large inputs
- poor contract scalability
- unnecessary blockchain storage growth

Proof of Concept:

1. Deploy the contract.

2. Call:
   heavyWrites(100000);

3. The function performs three storage writes during every iteration.

4. Gas usage increases rapidly as the loop executes.

5. The transaction eventually exceeds the available gas limit.

6. The transaction reverts with an Out-of-Gas error.

Root Cause:

The function performs repeated storage writes inside an unbounded loop
controlled entirely by user input.

No validation exists to restrict the maximum number of iterations.

Recommendation:

Restrict the maximum batch size before executing the loop.

Example:

require(n <= 100, "Batch too large");

Additionally:
- use memory variables for intermediate calculations
- minimize storage writes inside loops
- process large operations in multiple batches

*/

// Patched code
contract RepeatedStorageWritesPatched {

    uint256 public counter;
    uint256 public lastValue;

    uint256[] public history;

    uint256 public constant MAX_BATCH = 100;

    function optimizedWrites(uint256 n)
        external
    {
        require(
            n <= MAX_BATCH,
            "Batch too large"
        );

        /*
            Memory variables
        */
        uint256 tempCounter = counter;
        uint256 tempLastValue;

        /*
            Cheap operations in memory
        */
        for (
            uint256 i = 0;
            i < n;
            i++
        ) {
            tempCounter++;
            tempLastValue = i;
        }

        /*
            Single storage updates
        */
        counter = tempCounter;
        lastValue = tempLastValue;

        /*
            Bounded storage writes
        */
        for (
            uint256 i = 0;
            i < n;
            i++
        ) {
            history.push(i);
        }
    }

    function getHistoryLength()
        external
        view
        returns (uint256)
    {
        return history.length;
    }
}