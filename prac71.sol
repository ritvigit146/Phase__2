// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger out-of-gas scenario
CONCEPT: Execution failure
=========================================================

OBJECTIVE

- Understand what "out of gas" means
- See how loops can cause execution failure
- Learn why gas limits exist
- Think like an auditor about DOS risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every Ethereum transaction has a GAS LIMIT.

---------------------------------------------------------

If execution consumes more gas than available:

→ transaction REVERTS automatically

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Out-of-gas (OOG) is NOT a normal revert.

It is a HARD EXECUTION FAILURE.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Out-of-gas scenarios cause:

- failed transactions
- stuck operations
- denial of service (DOS)
- unusable functions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

OOG risks appear in:

- loops over arrays
- batch processing
- staking reward distribution
- token airdrops
- NFT mint batches

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- loop bounds
- gas estimation
- worst-case inputs
- storage-heavy iterations
- external call loops

=========================================================
OUT-OF-GAS CONTRACT
=========================================================
*/
contract OutOfGasDemoVul {

    uint256[] public data;

    /*
        Anyone can grow the array indefinitely.
    */
    function addMany(uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            data.push(i);
        }
    }

    /*
    =====================================================
    VULNERABILITY

    Iterates over the entire storage array.

    As the array grows larger, this function may
    exceed the block gas limit and become unusable.
    =====================================================
    */
    function dangerousLoop() external {

        uint256 sum = 0;

        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
            data[i] = sum;
        }
    }

    function getLength()
        external
        view
        returns (uint256)
    {
        return data.length;
    }
}

/*
=========================================================
EXECUTION FLOW (OUT-OF-GAS SCENARIO)
=========================================================

STEP 1:
Deploy OutOfGasDemo

=========================================================
STEP 2:
CALL:
addMany(10000)

=========================================================

Array grows to:
10000 elements

=========================================================
STEP 3:
CALL:
dangerousLoop()

=========================================================

STEP-BY-STEP EXECUTION
=========================================================

STEP 1:
sum = 0

---------------------------------------------------------

STEP 2:
i = 0 → read data[0]

---------------------------------------------------------

STEP 3:
data[0] updated

---------------------------------------------------------

STEP 4:
i = 1 → read data[1]

---------------------------------------------------------

(repeats thousands of times)

=========================================================
GAS CONSUMPTION GROWS
=========================================================

Each iteration costs:

- storage read
- storage write
- loop increment
- memory operations

=========================================================
CRITICAL MOMENT
=========================================================

At some iteration:

gas remaining < required gas

=========================================================
RESULT
=========================================================

TRANSACTION FAILS:

OUT OF GAS (OOG)

=========================================================
IMPORTANT BEHAVIOR
=========================================================

When OOG happens:

- entire transaction REVERTS
- ALL state changes rollback
- no partial execution persists

=========================================================
FINAL RESULT
=========================================================

data remains unchanged after failure

=========================================================
WHY THIS HAPPENS
=========================================================

Ethereum enforces gas limit per block:

→ prevents infinite computation
→ protects network from abuse

=========================================================
SAFE VERSION TRACE
=========================================================

CALL:
safeProcess(100)

=========================================================

STEP 1:
limit checked

---------------------------------------------------------

limit <= 100

=========================================================
STEP 2:
loop executes safely

---------------------------------------------------------

only 100 iterations

=========================================================
STEP 3:
execution completes successfully

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Out-of-gas is a:

---------------------------------------------------------
HARD EXECUTION FAILURE
---------------------------------------------------------

not a normal revert.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED LOOPS
---------------------------------------------------------

can exceed gas limit

---------------------------------------------------------
2. STORAGE INSIDE LOOP
---------------------------------------------------------

accelerates gas exhaustion

---------------------------------------------------------
3. USER-CONTROLLED INPUT SIZE
---------------------------------------------------------

attackers can force OOG

---------------------------------------------------------
4. DOS VIA GAS LIMIT
---------------------------------------------------------

contract becomes unusable

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- increase array size
- trigger expensive loops
- force OOG condition
- block contract execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can loop exceed gas limit?
- Is input size bounded?
- Are storage writes inside loops?
- What is worst-case gas cost?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors calculate:

---------------------------------------------------------
GAS PER ITERATION × MAX SIZE
---------------------------------------------------------

to ensure safety.

=========================================================
BEST PRACTICES
=========================================================

- Always bound loops
- Avoid storage writes in loops
- Use batching techniques
- Validate input size
- Design O(1) or O(log n) logic

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Allow dynamic batch processing
2. Prevent OOG using chunking
3. Compare safe vs unsafe loops
4. Add gas estimator function

BONUS:
Create pagination-based processing system.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Out-of-gas causes transaction failure
- Gas limits protect Ethereum network
- Large loops are dangerous
- Storage operations are expensive
- OOG reverts entire transaction
- Input size must be controlled
- Gas estimation is critical
- Auditors analyze worst-case execution
- Batching avoids gas exhaustion
- Safe design prevents DOS attacks

=========================================================
*/
/*
Audit Report

Title: Unbounded Loop Leading to Out-of-Gas Denial of Service

Severity: High because the function may become permanently unusable as the
array grows, causing transaction failures due to exceeding the block gas limit.

Location:
Contract: OutOfGasDemoVul
Function: dangerousLoop()

Vulnerability Description:

The dangerousLoop() function iterates over the entire storage array.

As the data array grows, the number of storage reads and storage writes
increases linearly. Since there is no upper limit on the loop, the
transaction may consume more gas than the block gas limit.

When this happens, the transaction runs Out-of-Gas (OOG) and reverts,
making the function impossible to execute for large arrays.

Impact:

An attacker or any user can continuously increase the size of the
data array using addMany().

As the array grows:

- dangerousLoop() eventually exceeds the gas limit
- every execution reverts
- contract functionality becomes unavailable
- causes Denial of Service (DoS)

Proof of Concept:

1. Deploy the contract.

2. Call:
   addMany(10000)

3. Call:
   dangerousLoop()

4. The function starts processing every array element.

5. Gas consumption exceeds the available gas limit.

6. Transaction reverts with an Out-of-Gas error.

Root Cause:

The function iterates over an unbounded storage array.

No maximum loop limit or batching mechanism exists to control the amount
of work performed in a single transaction.

Recommendation:

Process the array in small batches instead of the entire array.

Example:

function safeProcess(uint256 start, uint256 batchSize) external {
    require(batchSize <= 100, "Batch too large");
    require(start + batchSize <= data.length, "Out of bounds");

    uint256 sum = 0;

    for (uint256 i = start; i < start + batchSize; i++) {
        sum += data[i];
        data[i] = sum;
    }
}

*/

// Patched code
contract OutOfGasDemoPatched {

    uint256[] public data;

    /*
        Prevent extremely large additions
        in a single transaction.
    */
    function addMany(uint256 n) external {

        require(
            n <= 100,
            "Batch too large"
        );

        for (uint256 i = 0; i < n; i++) {
            data.push(i);
        }
    }

    /*
    =====================================================
    SAFE PROCESSING

    Only processes a limited batch instead
    of the entire array.
    =====================================================
    */
    function safeProcess(
        uint256 start,
        uint256 batchSize
    )
        external
    {
        require(
            batchSize <= 100,
            "Batch too large"
        );

        require(
            start + batchSize <= data.length,
            "Out of bounds"
        );

        uint256 sum = 0;

        for (
            uint256 i = start;
            i < start + batchSize;
            i++
        ) {
            sum += data[i];
            data[i] = sum;
        }
    }

    function getLength()
        external
        view
        returns (uint256)
    {
        return data.length;
    }
}