// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Stress test repeated calls
CONCEPT: Stability testing
=========================================================

OBJECTIVE

- Understand system behavior under repeated calls
- Learn how state grows over time
- Observe gas accumulation risks
- Think like auditor performing stress tests

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Repeated function calls simulate real-world load.

---------------------------------------------------------

Each call:
modifies state
consumes gas
adds cumulative load

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Stress testing is used to detect:

- gas exhaustion
- storage bloating
- performance degradation
- DOS risks

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

In real systems:

- users call contracts repeatedly
- bots interact heavily
- protocols accumulate state over time

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors test:

- repeated execution stability
- state growth over time
- gas scaling behavior
- worst-case repeated usage
- storage accumulation

=========================================================
STRESS TEST CONTRACT
=========================================================
*/
contract StressTestCallsVul {

    uint256 public counter;
    uint256 public totalCalls;

    uint256[] public history;

    function singleCall(uint256 value)
        public
    {
        counter++;
        totalCalls++;

        history.push(value);
    }

    /*
    =====================================================
    VULNERABILITY

    User controls "times".

    A very large value can exceed the block gas limit,
    causing the transaction to revert.
    =====================================================
    */
    function stressTest(uint256 times)
        external
    {
        for (uint256 i = 0; i < times; i++) {
            singleCall(i);
        }
    }

    /*
        Gas-inefficient external self-call.
    */
    function externalStyleStress(uint256 times)
        external
    {
        for (uint256 i = 0; i < times; i++) {
            this.singleCall(i);
        }
    }

    function reset() external {
        counter = 0;
        totalCalls = 0;
        delete history;
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
Deploy StressTestCalls

=========================================================
TRACE:
stressTest(5)
=========================================================

STEP 1:
i = 0

---------------------------------------------------------

singleCall(0)

=========================================================
STEP 2
=========================================================

STATE CHANGES:

counter++
totalCalls++
history.push(0)

=========================================================
STEP 3
=========================================================

i = 1 → repeat

=========================================================
STEP 4
=========================================================

i = 2 → repeat

=========================================================
STEP 5
=========================================================

i = 3 → repeat

=========================================================
STEP 6
=========================================================

i = 4 → repeat

=========================================================
FINAL STATE
=========================================================

---------------------------------------------------------
counter
---------------------------------------------------------

= 5

---------------------------------------------------------
totalCalls
---------------------------------------------------------

= 5

---------------------------------------------------------
history
---------------------------------------------------------

[0,1,2,3,4]

=========================================================
IMPORTANT OBSERVATION
=========================================================

Each loop iteration:

---------------------------------------------------------
1 storage increment
1 storage increment
1 array push
---------------------------------------------------------

Gas grows quickly.

=========================================================
TRACE:
externalStyleStress()
=========================================================

STEP 1:
this.singleCall(i)

---------------------------------------------------------

IMPORTANT:

This creates EXTERNAL CALLS to same contract.

=========================================================
STEP 2
=========================================================

Execution context switches:

Contract → Contract (external call)

=========================================================
STEP 3
=========================================================

Each iteration:

- external call overhead
- higher gas usage
- more execution cost

=========================================================
IMPORTANT DIFFERENCE
=========================================================

---------------------------------------------------------
singleCall()
---------------------------------------------------------

cheap internal call

---------------------------------------------------------

---------------------------------------------------------
this.singleCall()
---------------------------------------------------------

expensive external call

=========================================================
STRESS TEST INSIGHT
=========================================================

Repeated calls reveal:

- gas scaling issues
- storage growth
- execution bottlenecks
- stability limits

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

=========================================================
TEST 1
=========================================================

Call:
stressTest(10)

EXPECTED:
fast execution

=========================================================
STEP 2
=========================================================

Call:
stressTest(1000)

EXPECTED:
high gas usage / possible failure

=========================================================
TEST 3
=========================================================

Call:
externalStyleStress(10)

EXPECTED:
higher gas than internal version

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Repeated calls can cause:

---------------------------------------------------------
GAS DOS
---------------------------------------------------------

AND

---------------------------------------------------------
STORAGE BLOAT
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNBOUNDED REPEATED CALLS
---------------------------------------------------------

can exhaust gas

---------------------------------------------------------
2. STORAGE GROWTH
---------------------------------------------------------

array keeps increasing

---------------------------------------------------------
3. EXTERNAL CALL OVERHEAD
---------------------------------------------------------

increases gas significantly

---------------------------------------------------------
4. SYSTEM INSTABILITY
---------------------------------------------------------

becomes unscalable under load

=========================================================
ATTACK THINKING
=========================================================

Attackers may:

- spam function calls
- increase gas usage
- force storage growth
- degrade protocol performance

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors test:

- repeated call behavior
- worst-case gas usage
- storage scaling
- external call risks
- system stability under load

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors simulate:

---------------------------------------------------------
HIGH-FREQUENCY USAGE
---------------------------------------------------------

to find failure points.

=========================================================
BEST PRACTICES
=========================================================

- Avoid unbounded loops
- Minimize storage writes per call
- Prefer batch processing
- Avoid unnecessary external calls
- Design for scalability

=========================================================
MINI CHALLENGE
=========================================================

Modify contract:

1. Limit stressTest to 100 calls
2. Replace storage writes with events
3. Compare internal vs external call gas
4. Add gas measurement logging

BONUS:
Create batch-stress-safe architecture.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Repeated calls simulate real load
- Gas grows with execution frequency
- Storage accumulates over time
- External calls are more expensive
- Stress testing reveals vulnerabilities
- System scalability must be designed
- Auditors simulate heavy usage scenarios
- Unbounded execution is dangerous
- Storage + loops = high risk pattern
- Stability testing is critical for security

=========================================================
*/
/*
Audit Report

Title: Unbounded Loop Leading to Out-of-Gas Denial of Service

Severity: Medium because an unbounded user-controlled loop can exceed the
block gas limit, causing transactions to revert and making the function
unusable for large inputs.

Location:
Contract: StressTestCallsVul
Function: stressTest(uint256 times)

Vulnerability Description:

The stressTest() function executes a loop based entirely on the
user-supplied parameter `times`.

    for (uint256 i = 0; i < times; i++) {
        singleCall(i);
    }

There is no upper limit on the number of iterations.

Each iteration performs multiple storage writes through
singleCall(), including:

    counter++;
    totalCalls++;
    history.push(value);

As the value of `times` increases, gas consumption grows linearly.
If a sufficiently large value is supplied, the transaction will
run out of gas and revert.

This creates a Denial of Service (DoS) condition where the function
cannot successfully execute for large inputs.

Impact:

- Transactions may fail due to Out-of-Gas.
- Users waste gas on reverted transactions.
- Function becomes unusable for very large inputs.
- Storage growth further increases execution costs.
- Poor scalability under heavy usage.

Proof of Concept:

1. Deploy StressTestCallsVul.

2. Call:

    stressTest(100000)

3. The function enters the loop and repeatedly calls:

    singleCall(i);

4. Each iteration performs:

    counter++;
    totalCalls++;
    history.push(i);

5. Gas consumption continues increasing.

6. Eventually the transaction exceeds the block gas limit.

7. Transaction reverts with an Out-of-Gas error.

Root Cause:

The developer allows a user-controlled loop to execute without
restricting the maximum number of iterations.

The function performs expensive storage operations inside the loop,
making execution cost proportional to the user-provided input.

Recommendation:

Limit the maximum batch size before entering the loop.

Example:

    uint256 public constant MAX_BATCH = 100;

    require(
        times <= MAX_BATCH,
        "Batch too large"
    );

Alternatively, implement pagination or batch processing so large
workloads are divided across multiple transactions.

*/

// Patched code
contract StressTestCallsPatched {

    uint256 public counter;
    uint256 public totalCalls;

    uint256[] public history;

    uint256 public constant MAX_BATCH = 100;

    function singleCall(uint256 value)
        internal
    {
        counter++;
        totalCalls++;

        history.push(value);
    }

    /*
    =====================================================
    SAFE VERSION

    Limits the maximum number of iterations to prevent
    Out-of-Gas (OOG) attacks.
    =====================================================
    */
    function stressTest(uint256 times)
        external
    {
        require(
            times <= MAX_BATCH,
            "Batch too large"
        );

        for (uint256 i = 0; i < times; i++) {
            singleCall(i);
        }
    }

    /*
    =====================================================
    SAFE VERSION

    Uses an internal call instead of an external self-call,
    reducing gas consumption and avoiding unnecessary
    execution context switches.
    =====================================================
    */
    function optimizedStress(uint256 times)
        external
    {
        require(
            times <= MAX_BATCH,
            "Batch too large"
        );

        for (uint256 i = 0; i < times; i++) {
            singleCall(i);
        }
    }

    function reset() external {
        counter = 0;
        totalCalls = 0;
        delete history;
    }

    function getHistoryLength()
        external
        view
        returns (uint256)
    {
        return history.length;
    }
}