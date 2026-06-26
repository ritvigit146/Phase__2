// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trace external call execution
CONCEPT: Control transfer awareness
=========================================================

OBJECTIVE

- Learn how execution control moves externally
- Understand execution-context switching
- Trace msg.sender across contracts
- Think like auditor during external interactions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

When Contract A calls Contract B:

execution control LEAVES A
and ENTERS B.

---------------------------------------------------------

This is one of the MOST IMPORTANT
security concepts in Solidity.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls are NOT normal jumps.

---------------------------------------------------------

Execution temporarily transfers to:

UNTRUSTED CODE.

---------------------------------------------------------

The called contract controls execution flow
until it returns or reverts.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most Solidity vulnerabilities involve:

- external execution
- reentrancy
- callback attacks
- malicious contracts
- trust assumptions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls exist in:

- token transfers
- swaps
- lending protocols
- NFT marketplaces
- staking systems
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors trace:

- execution switching
- msg.sender transitions
- state before/after calls
- reentrancy windows
- callback opportunities

=========================================================
TARGET CONTRACT
=========================================================
*/

contract ExternalTarget {

    /*
        STORE LAST CALLER
    */
    address public lastCaller;

    /*
        TRACK EXECUTIONS
    */
    uint256 public executionCounter;

    /*
    =====================================================
    TARGET FUNCTION
    =====================================================
    */

    function targetFunction()
        external
    {

        /*
        =================================================
        EXECUTION CONTEXT NOW INSIDE TARGET CONTRACT
        =================================================

        msg.sender becomes:
        calling contract address.
        */

        lastCaller = msg.sender;

        /*
            Increment execution count.
        */
        executionCounter++;
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract ExecutionTracer {

    /*
        TARGET CONTRACT REFERENCE
    */
    ExternalTarget public target;

    /*
        LOCAL EXECUTION TRACKING
    */
    uint256 public localCounter;

    /*
        TRACK EXECUTION STEPS
    */
    string public executionStage;

    /*
        TRACK LAST msg.sender
    */
    address public lastObservedSender;

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        /*
            Save target contract.
        */
        target = ExternalTarget(_target);
    }

    /*
    =====================================================
    TRACE EXTERNAL EXECUTION
    =====================================================
    */

    function traceExecution()
        external
    {

        /*
        =================================================
        STEP 1
        =================================================

        Execution currently inside:
        ExecutionTracer contract.
        */

        executionStage =
            "Before external call";

        /*
            msg.sender here:
            ORIGINAL USER.
        */
        lastObservedSender =
            msg.sender;

        /*
            Local state update.
        */
        localCounter++;

        /*
        =================================================
        STEP 2
        =================================================

        EXTERNAL CALL HAPPENS HERE.

        CONTROL LEAVES:
        ExecutionTracer

        CONTROL ENTERS:
        ExternalTarget
        */

        target.targetFunction();

        /*
        =================================================
        STEP 3
        =================================================

        External execution finished.

        CONTROL RETURNS:
        back to ExecutionTracer.
        */

        executionStage =
            "After external call";
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy ExternalTarget

---------------------------------------------------------

STEP 2:
Deploy ExecutionTracer

Constructor input:
ExternalTarget address

=========================================================
TRACE:
traceExecution()
=========================================================

STEP 1:
User calls:

traceExecution()

=========================================================
STEP 2
=========================================================

Execution enters:
ExecutionTracer

---------------------------------------------------------

Current contract:
ExecutionTracer

---------------------------------------------------------

msg.sender:
ORIGINAL USER

=========================================================
STEP 3
=========================================================

executionStage =
"Before external call"

---------------------------------------------------------

localCounter++

=========================================================
STEP 4
=========================================================

CRITICAL MOMENT:

target.targetFunction()

=========================================================
IMPORTANT
=========================================================

CONTROL LEAVES:
ExecutionTracer

---------------------------------------------------------

Execution CONTEXT switches externally.

=========================================================
STEP 5
=========================================================

Execution enters:
ExternalTarget

---------------------------------------------------------

Current contract:
ExternalTarget

=========================================================
IMPORTANT msg.sender CHANGE
=========================================================

Inside ExternalTarget:

msg.sender =
ExecutionTracer contract

---------------------------------------------------------

NOT original user.

=========================================================
STEP 6
=========================================================

ExternalTarget executes:

---------------------------------------------------------

lastCaller = ExecutionTracer

---------------------------------------------------------

executionCounter++

=========================================================
STEP 7
=========================================================

ExternalTarget finishes execution.

---------------------------------------------------------

CONTROL RETURNS:
ExecutionTracer

=========================================================
STEP 8
=========================================================

Execution continues AFTER external call.

---------------------------------------------------------

executionStage =
"After external call"

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
ExecutionTracer.localCounter
---------------------------------------------------------

1

---------------------------------------------------------
ExternalTarget.executionCounter
---------------------------------------------------------

1

---------------------------------------------------------
ExternalTarget.lastCaller
---------------------------------------------------------

ExecutionTracer address

=========================================================
CRITICAL SECURITY UNDERSTANDING
=========================================================

During external call:

---------------------------------------------------------
YOUR CONTRACT STOPS EXECUTING
---------------------------------------------------------

and

---------------------------------------------------------
ANOTHER CONTRACT TAKES CONTROL
---------------------------------------------------------

=========================================================
THIS IS DANGEROUS BECAUSE
=========================================================

External contract may:

- revert
- reenter
- consume gas
- manipulate execution
- attack assumptions

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Every external call means:

---------------------------------------------------------
TRUSTING UNKNOWN EXECUTION
---------------------------------------------------------

=========================================================
CONTROL TRANSFER VISUALIZATION
=========================================================

User
  |
  v
ExecutionTracer
  |
  | external call
  v
ExternalTarget
  |
  | return
  v
ExecutionTracer resumes

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy ExternalTarget

---------------------------------------------------------

STEP 2:
Deploy ExecutionTracer

Input:
ExternalTarget address

---------------------------------------------------------

STEP 3:
Call:
traceExecution()

=========================================================
STEP 4
=========================================================

Check:
executionStage()

EXPECTED:
"After external call"

=========================================================
STEP 5
=========================================================

Check:
localCounter()

EXPECTED:
1

=========================================================
STEP 6
=========================================================

Open ExternalTarget

---------------------------------------------------------

Check:
executionCounter()

EXPECTED:
1

---------------------------------------------------------

Check:
lastCaller()

EXPECTED:
ExecutionTracer address

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External calls create:

---------------------------------------------------------
EXECUTION BOUNDARIES
---------------------------------------------------------

and

---------------------------------------------------------
TRUST BOUNDARIES
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External contract calls back unexpectedly.

---------------------------------------------------------
2. msg.sender CONFUSION
---------------------------------------------------------

Authentication assumptions fail.

---------------------------------------------------------
3. FAILURE PROPAGATION
---------------------------------------------------------

External revert breaks execution.

---------------------------------------------------------
4. MALICIOUS CALLBACKS
---------------------------------------------------------

Execution flow manipulated externally.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers abuse:

- external execution windows
- callback opportunities
- temporary state exposure
- trust assumptions

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every external jump
2. Control-transfer timing
3. State before call
4. State after call
5. Reentrancy possibilities

=========================================================
WHY CONTROL TRANSFER IS CRITICAL
=========================================================

Most major Solidity exploits happen
during external execution.

---------------------------------------------------------

Understanding control transfer
is foundational for auditing.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfer
2. Add malicious callback
3. Add reentrancy attack
4. Add nested external chain

BONUS:
Trace execution using Remix debugger.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls transfer execution control
- msg.sender changes during nested calls
- Contracts temporarily stop execution
- External contracts are untrusted
- Control eventually returns after execution
- Reentrancy occurs during external execution
- Auditors trace every external jump
- Execution context changes externally
- External calls create attack surface
- Control-transfer awareness is critical for auditing

=========================================================
*/
/*
Audit Report

Title: No Security Vulnerability Identified in traceExecution()

Severity: Informational

Location:
Contract: ExecutionTracer
Function: traceExecution()

Vulnerability Description:

No exploitable vulnerability was identified in the traceExecution() function.

The function demonstrates external control transfer by calling
ExternalTarget.targetFunction(). The contract does not:

- hold ETH
- transfer tokens
- perform privileged operations
- rely on authentication
- use delegatecall
- ignore low-level call results

The external call is made to a trusted contract reference and no
security-sensitive state can be exploited under the current implementation.

Impact:

No security impact.

The contract is intended as an educational example for understanding
execution flow and msg.sender transitions.

Proof of Concept:

1. Deploy ExternalTarget.
2. Deploy ExecutionTracer with the ExternalTarget address.
3. Call traceExecution().
4. Observe:
   - localCounter increments.
   - executionStage changes to "After external call".
   - ExternalTarget.executionCounter increments.
   - ExternalTarget.lastCaller equals the ExecutionTracer contract address.

The execution completes successfully without exposing a security issue.

Root Cause:

No vulnerability exists in the current implementation.

The contract performs an external call only to demonstrate execution
context switching and does not expose sensitive assets or privileged
functionality.

Recommendation:

No code changes are required.

For future development, continue following the
Checks-Effects-Interactions (CEI) pattern when interacting with
untrusted external contracts, especially if ETH transfers, token
transfers, callbacks, or privileged state changes are introduced.

*/