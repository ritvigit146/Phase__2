// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Chain multiple external calls
CONCEPT: Complex execution
=========================================================

OBJECTIVE

- Learn chained external execution flow
- Understand multi-contract interactions
- Learn failure propagation behavior
- Think like protocol auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

One contract may call:
another contract,
which calls another contract.

---------------------------------------------------------

Execution chains become:

Contract A
    ->
Contract B
    ->
Contract C

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Every external call:

- changes execution context
- changes msg.sender
- creates attack surface
- may revert entire chain

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern DeFi heavily relies on:

multi-contract execution chains.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Chained calls appear in:

- swaps
- lending
- flash loans
- routers
- bridges
- multicall systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- nested external calls
- failure propagation
- trust assumptions
- reentrancy windows
- state consistency

=========================================================
CONTRACT C
FINAL TARGET
=========================================================
*/

contract ContractC {

    /*
        TRACK EXECUTION
    */
    uint256 public counter;

    /*
    =====================================================
    FINAL EXECUTION
    =====================================================
    */

    function finalStep()
        external
    {

        /*
            Increment execution counter.
        */
        counter++;
    }

    /*
    =====================================================
    FAILING FUNCTION
    =====================================================
    */

    function failStep()
        external
        pure
    {

        revert("Contract C failure");
    }
}

/*
=========================================================
CONTRACT B
MIDDLE CONTRACT
=========================================================
*/

contract ContractB {

    /*
        STORE CONTRACT C
    */
    ContractC public contractC;

    /*
        TRACK EXECUTION
    */
    uint256 public middleCounter;

    /*
        CONSTRUCTOR
    */
    constructor(address _contractC)
    {

        contractC = ContractC(_contractC);
    }

    /*
    =====================================================
    CALL CONTRACT C
    =====================================================
    */

    function callFinalStep()
        external
    {

        /*
            Local state update.
        */
        middleCounter++;

        /*
            EXTERNAL CALL:
            Contract B -> Contract C
        */
        contractC.finalStep();
    }

    /*
    =====================================================
    CALL FAILING FUNCTION
    =====================================================
    */

    function callFailingStep()
        external
    {

        /*
            State update.
        */
        middleCounter++;

        /*
            External call that reverts.
        */
        contractC.failStep();
    }
}

/*
=========================================================
CONTRACT A
ENTRY CONTRACT
=========================================================
*/

contract ContractA {

    /*
        STORE CONTRACT B
    */
    ContractB public contractB;

    /*
        TRACK EXECUTION
    */
    uint256 public entryCounter;

    /*
        CONSTRUCTOR
    */
    constructor(address _contractB)
    {

        contractB = ContractB(_contractB);
    }

    /*
    =====================================================
    START EXECUTION CHAIN
    =====================================================
    */

    function startChain()
        external
    {

        /*
            Local state update.
        */
        entryCounter++;

        /*
            EXTERNAL CALL:
            Contract A -> Contract B
        */
        contractB.callFinalStep();
    }

    /*
    =====================================================
    START FAILING CHAIN
    =====================================================
    */

    function startFailingChain()
        external
    {

        /*
            State update.
        */
        entryCounter++;

        /*
            Nested call chain eventually fails.
        */
        contractB.callFailingStep();
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

DEPLOY ORDER:

1. Deploy ContractC
2. Deploy ContractB
3. Deploy ContractA

---------------------------------------------------------

Constructor wiring:

ContractB -> ContractC
ContractA -> ContractB

=========================================================
TRACE:
startChain()
=========================================================

STEP 1:
User calls:

ContractA.startChain()

=========================================================
STEP 2
=========================================================

ContractA updates storage.

---------------------------------------------------------

entryCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 3
=========================================================

External call:

ContractA
    ->
ContractB.callFinalStep()

=========================================================
STEP 4
=========================================================

Execution enters:
ContractB

---------------------------------------------------------

middleCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 5
=========================================================

Another external call:

ContractB
    ->
ContractC.finalStep()

=========================================================
STEP 6
=========================================================

Execution enters:
ContractC

---------------------------------------------------------

counter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
FINAL RESULT
=========================================================

All contracts updated successfully.

---------------------------------------------------------

ContractA.entryCounter = 1

ContractB.middleCounter = 1

ContractC.counter = 1

=========================================================
IMPORTANT EXECUTION UNDERSTANDING
=========================================================

Execution CONTEXT switches
during every external call.

=========================================================
msg.sender FLOW
=========================================================

---------------------------------------------------------
Inside ContractA
---------------------------------------------------------

msg.sender = User

---------------------------------------------------------
Inside ContractB
---------------------------------------------------------

msg.sender = ContractA

---------------------------------------------------------
Inside ContractC
---------------------------------------------------------

msg.sender = ContractB

=========================================================
VERY IMPORTANT
=========================================================

msg.sender changes at EACH hop.

=========================================================
FAILING CHAIN TRACE
=========================================================

CALL:
startFailingChain()

=========================================================

STEP 1:
ContractA updates:

entryCounter++

=========================================================
STEP 2
=========================================================

ContractA calls:
ContractB

=========================================================
STEP 3
=========================================================

ContractB updates:

middleCounter++

=========================================================
STEP 4
=========================================================

ContractB calls:
ContractC.failStep()

=========================================================
STEP 5
=========================================================

ContractC reverts:

"Contract C failure"

=========================================================
IMPORTANT
=========================================================

Revert propagates upward.

---------------------------------------------------------

ContractC
    ->
ContractB
    ->
ContractA

=========================================================
FINAL RESULT
=========================================================

ENTIRE transaction reverts.

---------------------------------------------------------

ALL previous state updates rollback.

=========================================================
ROLLBACK OBSERVATION
=========================================================

Even though:

entryCounter++

and

middleCounter++

already executed,

---------------------------------------------------------

ALL changes revert atomically.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy ContractC

---------------------------------------------------------

STEP 2:
Deploy ContractB

Input:
ContractC address

---------------------------------------------------------

STEP 3:
Deploy ContractA

Input:
ContractB address

---------------------------------------------------------

STEP 4:
Call:
startChain()

---------------------------------------------------------

STEP 5:
Check all counters

EXPECTED:
all incremented

=========================================================
STEP 6
=========================================================

Call:
startFailingChain()

---------------------------------------------------------

EXPECTED:
full transaction revert

=========================================================
STEP 7
=========================================================

Check counters again.

---------------------------------------------------------

IMPORTANT:
No new increments occurred.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Nested external calls create:

---------------------------------------------------------
COMPLEX EXECUTION FLOW
---------------------------------------------------------

and

---------------------------------------------------------
LARGER ATTACK SURFACE
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

Nested calls may reenter earlier contracts.

---------------------------------------------------------
2. FAILURE PROPAGATION
---------------------------------------------------------

One revert breaks entire chain.

---------------------------------------------------------
3. msg.sender CONFUSION
---------------------------------------------------------

Authentication assumptions fail.

---------------------------------------------------------
4. TRUST ASSUMPTIONS
---------------------------------------------------------

External contracts may behave maliciously.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers abuse:

- nested execution
- callback chains
- external state assumptions
- recursive interactions

---------------------------------------------------------

Complexity increases risk heavily.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors trace:

- every external jump
- every state mutation
- every revert path
- msg.sender transitions
- reentrancy windows

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors build:

---------------------------------------------------------
FULL EXECUTION GRAPH
---------------------------------------------------------

to understand:

- control flow
- state dependencies
- attack surface

=========================================================
WHY COMPLEXITY IS DANGEROUS
=========================================================

More external calls =
more assumptions.

---------------------------------------------------------

More assumptions =
more vulnerabilities.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfers
2. Add low-level call()
3. Add try/catch handling
4. Add malicious reentrant contract

BONUS:
Create mini DeFi router chain.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can chain external calls
- msg.sender changes across contracts
- Nested execution increases complexity
- Reverts propagate upward
- Transactions rollback atomically
- External calls create attack surface
- Multi-contract systems are harder to audit
- Auditors trace full execution chains
- Complex execution increases security risk
- Inter-contract trust assumptions matter heavily

=========================================================
*/
/*
Audit Report

Title: No Security Vulnerability Identified in Chained External Calls

Severity: Informational

Location:
Contract: ContractA
Function: startChain()

Contract: ContractA
Function: startFailingChain()

Contract: ContractB
Function: callFinalStep()

Contract: ContractB
Function: callFailingStep()

Contract: ContractC
Function: finalStep()

Contract: ContractC
Function: failStep()

Vulnerability Description:

The contracts demonstrate chained external calls between multiple
contracts:

    ContractA
        ->
    ContractB
        ->
    ContractC

The implementation correctly relies on Solidity's built-in transaction
atomicity. If any contract in the execution chain reverts, the revert
automatically propagates back through every caller, causing the entire
transaction to revert and restoring all previously modified state.

No inconsistent state, unchecked external call, reentrancy issue, or
access-control vulnerability is present in the current implementation.

Impact:

No direct security impact.

When the final contract reverts:

- entryCounter is restored.
- middleCounter is restored.
- counter remains unchanged.
- Entire transaction reverts safely.

The blockchain state always remains consistent.

Proof of Concept:

1. Deploy ContractC.

2. Deploy ContractB using the address of ContractC.

3. Deploy ContractA using the address of ContractB.

4. Call:

    startFailingChain()

Execution flow:

    ContractA
        entryCounter++

            ↓

    ContractB
        middleCounter++

            ↓

    ContractC
        failStep()

            ↓

        revert("Contract C failure")

5. The revert propagates:

    ContractC
        ->
    ContractB
        ->
    ContractA

6. Final state:

    entryCounter = unchanged

    middleCounter = unchanged

    counter = unchanged

7. Entire transaction is reverted.

Root Cause:

No vulnerability exists.

The observed behavior is the intended behavior of Solidity's atomic
transaction model, where any revert occurring in a nested external call
causes all previous state modifications within the same transaction to
be rolled back automatically.

Recommendation:

No security patch is required.

For production contracts, auditors may additionally recommend:

- Validate constructor addresses (non-zero and deployed contracts).
- Apply access control if only authorized users should initiate the
  execution chain.
- Use try/catch if partial failure handling is required.
- Review external calls for reentrancy if future versions introduce
  ETH transfers or callback functionality.

Conclusion:

No security vulnerabilities were identified during the review.

The contracts correctly demonstrate:

- Chained external execution
- msg.sender transitions
- Revert propagation
- Atomic transaction rollback
- Consistent state management

Overall Risk Rating: Informational
*/