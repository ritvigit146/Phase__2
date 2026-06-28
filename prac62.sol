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
contract ContractCVul {

    uint256 public counter;

    function finalStep() external {
        counter++;
    }

    function failStep() external pure {
        revert("Contract C failure");
    }
}

contract ContractBVul {

    address public contractC;
    uint256 public middleCounter;

    constructor(address _contractC) {
        contractC = _contractC;
    }

    function callFinalStep() external {

        middleCounter++;

        // Vulnerability: Ignore return value
        contractC.call(
            abi.encodeWithSignature("finalStep()")
        );
    }

    function callFailingStep() external {

        middleCounter++;

        // Vulnerability: Failure ignored
        contractC.call(
            abi.encodeWithSignature("failStep()")
        );
    }
}

contract ContractAVul {

    ContractBVul public contractB;

    uint256 public entryCounter;

    constructor(address _contractB) {
        contractB = ContractBVul(_contractB);
    }

    function startChain() external {

        entryCounter++;

        contractB.callFinalStep();
    }

    function startFailingChain() external {

        entryCounter++;

        // ContractB never reports failure
        contractB.callFailingStep();

        // Transaction still succeeds
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

Title: Unchecked Low-Level External Calls in Chained Execution

Severity: Medium because low-level call() does not automatically revert on
failure. Ignoring its return value allows execution to continue even when a
critical external call fails, leading to inconsistent contract state and
unexpected behavior.

Location:
Contract: ContractBVul
Functions:
- callFinalStep()
- callFailingStep()

Vulnerability Description:

The ContractBVul contract performs low-level external calls to ContractC
using address.call(), but it does not verify the returned success value.

Since low-level call() returns a boolean indicating whether the external
call succeeded, failing to check this value means that execution continues
even if the called contract reverts.

As a result, the transaction may appear successful while the intended
operation in ContractC never executes. This creates inconsistent state
between the contracts participating in the execution chain.

Impact:

An attacker or an unexpected failure in ContractC could cause:

- silent execution failures
- inconsistent state across multiple contracts
- incorrect execution tracking
- business logic continuing after failed operations
- unexpected protocol behavior

In complex DeFi protocols, ignoring failed external calls can result in
incorrect accounting, incomplete operations, or broken execution flows.

Proof of Concept:

1. Deploy ContractCVul.

2. Deploy ContractBVul using the address of ContractCVul.

3. Deploy ContractAVul using the address of ContractBVul.

4. Call:

   startFailingChain()

5. Execution flow:

   ContractA
      →
   ContractB
      →
   ContractC.failStep()

6. ContractC reverts with:

   "Contract C failure"

7. ContractBVul ignores the returned success value from call().

8. The transaction completes successfully instead of reverting.

9. Final state becomes:

   entryCounter = 1
   middleCounter = 1
   ContractC.counter = 0

This demonstrates that the execution chain is left in an inconsistent state.

Root Cause:

The contract uses low-level address.call() without checking the returned
success boolean.

Unlike normal Solidity interface calls, low-level call() never reverts
automatically. It returns:

(bool success, bytes memory returndata)

Developers must explicitly validate the success value to ensure the external
operation completed successfully.

Recommendation:

Always validate the return value of low-level calls.

Recommended mitigations include:

- capture the returned success boolean
- revert if success is false
- propagate failures to the caller
- use interface-based external calls whenever possible
- use low-level call() only when necessary and always check its result

Example:

(bool success, ) = contractC.call(
    abi.encodeWithSignature("finalStep()")
);

require(success, "Contract C call failed");

This ensures that any failure in the external contract causes the entire
transaction to revert, preserving atomicity and maintaining consistent
state across all contracts in the execution chain.

*/

// Patched code
contract ContractCPatched {

    uint256 public counter;

    function finalStep() external {
        counter++;
    }

    function failStep() external pure {
        revert("Contract C failure");
    }
}

contract ContractBPatched {

    address public contractC;
    uint256 public middleCounter;

    constructor(address _contractC) {
        contractC = _contractC;
    }

    function callFinalStep() external {

        middleCounter++;

        (bool success, ) =
            contractC.call(
                abi.encodeWithSignature("finalStep()")
            );

        require(success, "Contract C call failed");
    }

    function callFailingStep() external {

        middleCounter++;

        (bool success, ) =
            contractC.call(
                abi.encodeWithSignature("failStep()")
            );

        require(success, "Contract C reverted");
    }
}

contract ContractAPatched {

    ContractBPatched public contractB;

    uint256 public entryCounter;

    constructor(address _contractB) {
        contractB = ContractBPatched(_contractB);
    }

    function startChain() external {

        entryCounter++;

        contractB.callFinalStep();
    }

    function startFailingChain() external {

        entryCounter++;

        contractB.callFailingStep();

        // If ContractC fails,
        // entire transaction reverts.
    }
}