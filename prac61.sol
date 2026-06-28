// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Handle success boolean properly
CONCEPT: Safe call handling
=========================================================

OBJECTIVE

- Learn proper low-level call() handling
- Understand safe external interaction logic
- Learn transaction rollback protection
- Prevent silent external-call failures

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Low-level call() returns:

(bool success, bytes memory data)

---------------------------------------------------------

SAFE handling requires:

require(success)

---------------------------------------------------------

Otherwise:
external call failures may be ignored.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

External calls are:
UNTRUSTED EXECUTION.

---------------------------------------------------------

Target contracts may:

- revert
- reject ETH
- consume gas
- behave maliciously

---------------------------------------------------------

Safe code ALWAYS checks:
success boolean.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Unchecked calls caused:

- accounting corruption
- lost funds
- broken withdrawals
- inconsistent state
- DOS vulnerabilities

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Safe call handling used in:

- DeFi protocols
- vaults
- token bridges
- DAO systems
- exchanges
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- require(success)
- unchecked low-level calls
- rollback guarantees
- silent failure risks
- external interaction safety

=========================================================
TARGET CONTRACT
=========================================================
*/
contract CallTargetVul {

    uint256 public counter;

    function successFunction() external {
        counter++;
    }

    function failFunction() external pure {
        revert("Intentional failure");
    }

    receive() external payable {
        revert("ETH rejected");
    }
}

contract VulnerableCallHandler {

    bool public lastSuccess;
    bytes public lastData;
    uint256 public executionCounter;

    /*
    =====================================================
    VULNERABLE FUNCTION CALL
    =====================================================
    */

    function vulnerableFunctionCall(address target) external {

        executionCounter++;

        (bool success, bytes memory data) =
            target.call(
                abi.encodeWithSignature(
                    "successFunction()"
                )
            );

        // Stored only
        lastSuccess = success;
        lastData = data;

        // Missing require(success)
        // Execution continues even if call fails.
    }

    /*
    =====================================================
    VULNERABLE FAILING CALL
    =====================================================
    */

    function vulnerableFailingCall(address target) external {

        executionCounter++;

        (bool success, bytes memory data) =
            target.call(
                abi.encodeWithSignature(
                    "failFunction()"
                )
            );

        lastSuccess = success;
        lastData = data;

        // Failure ignored
    }

    /*
    =====================================================
    VULNERABLE ETH TRANSFER
    =====================================================
    */

    function vulnerableETHTransfer(
        address payable target
    )
        external
        payable
    {
        (bool success, bytes memory data) =
            target.call{value: msg.value}("");

        lastSuccess = success;
        lastData = data;

        // ETH transfer failure ignored
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy CallTarget

---------------------------------------------------------

STEP 2:
Deploy SafeCallHandler

=========================================================
TRACE:
safeFunctionCall()
=========================================================

STEP 1:
executionCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 2
=========================================================

Low-level call executes:

successFunction()

=========================================================
STEP 3
=========================================================

Target function succeeds.

---------------------------------------------------------

success = true

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

PASS

---------------------------------------------------------

Transaction succeeds safely.

=========================================================
FAILING CALL TRACE
=========================================================

CALL:
safeFailingCall()

=========================================================

STEP 1:
executionCounter++

---------------------------------------------------------

NEW VALUE:
2

=========================================================
STEP 2
=========================================================

External call executes:

failFunction()

=========================================================
STEP 3
=========================================================

Target contract reverts.

---------------------------------------------------------

success = false

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

FAILS

---------------------------------------------------------

TRANSACTION REVERTS

=========================================================
IMPORTANT ROLLBACK OBSERVATION
=========================================================

Even though:

executionCounter++

executed BEFORE call,

---------------------------------------------------------

ALL state changes rollback.

=========================================================
FINAL RESULT
=========================================================

executionCounter restored
to previous value.

=========================================================
WHY?
=========================================================

Ethereum transactions are:
ATOMIC.

---------------------------------------------------------

Either:
everything succeeds

OR

everything reverts.

=========================================================
ETH FAILURE TRACE
=========================================================

CALL:
safeETHTransfer()

VALUE:
1 ETH

=========================================================

STEP 1:
ETH sent to CallTarget.

=========================================================
STEP 2
=========================================================

receive() executes.

---------------------------------------------------------

receive() reverts intentionally.

=========================================================
STEP 3
=========================================================

call() returns:

success = false

=========================================================
STEP 4
=========================================================

require(success)

---------------------------------------------------------

Transaction fully reverts.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Safe external handling requires:

---------------------------------------------------------
CHECKING success
---------------------------------------------------------

on EVERY low-level call.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy CallTarget

---------------------------------------------------------

STEP 2:
Deploy SafeCallHandler

---------------------------------------------------------

STEP 3:
Call:
safeFunctionCall()

Input:
CallTarget address

---------------------------------------------------------

EXPECTED:
Success

=========================================================
STEP 4
=========================================================

Call:
safeFailingCall()

---------------------------------------------------------

EXPECTED:
Revert with:
"External call reverted"

=========================================================
STEP 5
=========================================================

Check:
executionCounter()

---------------------------------------------------------

EXPECTED:
unchanged due to rollback.

=========================================================
STEP 6
=========================================================

In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 7:
Call:
safeETHTransfer()

---------------------------------------------------------

EXPECTED:
Revert with:
"ETH transfer failed"

=========================================================
IMPORTANT LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() NEVER auto-reverts.

---------------------------------------------------------

It only returns:

success = true/false

---------------------------------------------------------

Developer decides:
how to handle failure.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED SUCCESS VALUES
---------------------------------------------------------

Classic Solidity vulnerability.

---------------------------------------------------------
2. SILENT FAILURES
---------------------------------------------------------

Execution continues incorrectly.

---------------------------------------------------------
3. ACCOUNTING CORRUPTION
---------------------------------------------------------

Internal state diverges from reality.

---------------------------------------------------------
4. DOS VIA REVERT
---------------------------------------------------------

Malicious contracts halt execution.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers intentionally:

- revert calls
- reject ETH
- break assumptions
- exploit unchecked failures

---------------------------------------------------------

Safe handling blocks these issues.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors search for:

---------------------------------------------------------
.call(
---------------------------------------------------------

without:

---------------------------------------------------------
require(success)
---------------------------------------------------------

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interactions
2. Failure paths
3. Return-value handling
4. Rollback guarantees
5. Silent-failure scenarios

=========================================================
BEST PRACTICE
=========================================================

ALWAYS:

---------------------------------------------------------
(bool success, ) = target.call(...)

require(success)
---------------------------------------------------------

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add try/catch
2. Decode revert messages
3. Emit failure events
4. Compare checked vs unchecked calls

BONUS:
Build ERC20 safe-transfer wrapper.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- call() returns success manually
- Low-level calls do not auto-revert
- require(success) ensures safe handling
- Reverts rollback all state changes
- Transactions are atomic
- External calls are untrusted
- Silent failures are dangerous
- Safe call handling prevents inconsistencies
- Auditors inspect low-level calls carefully
- Error handling is critical for Solidity security

=========================================================
*/
/*
Audit Report

Title: Unchecked Low-Level Call Return Value

Severity: Medium

Reason:
The contract performs low-level external calls using call() but, in the
vulnerable implementation, does not verify whether the call succeeded.

Ignoring the returned success boolean allows execution to continue even
when the external contract reverts or rejects the call, which can leave
the contract in an inconsistent state.

If critical state changes occur before or after the unchecked call,
accounting inconsistencies, incorrect execution flow, or fund loss may
occur.

Location:
Contract: VulnerableCallHandler

Functions:
- vulnerableFunctionCall()
- vulnerableFailingCall()
- vulnerableETHTransfer()

Vulnerability Description:

The vulnerable functions invoke external contracts using Solidity's
low-level call().

call() never automatically reverts.

Instead, it returns:

(bool success, bytes memory data)

The vulnerable implementation stores the returned success value but
never validates it.

As a result, if the external call fails, execution continues normally
instead of reverting the transaction.

This can create situations where internal state assumes an external
operation succeeded even though it actually failed.

Impact:

Unchecked call failures can result in:

- inconsistent contract state
- incorrect accounting
- silent transaction failures
- failed ETH transfers being treated as successful
- unexpected protocol behavior
- denial-of-service scenarios caused by ignored failures

Although no direct fund theft exists in this educational example, the
same pattern has caused serious vulnerabilities in production smart
contracts.

Proof of Concept:

1. Deploy CallTarget.

2. Deploy VulnerableCallHandler.

3. Call:

   vulnerableFailingCall(CallTarget)

4. The target contract executes failFunction(), which immediately
   reverts.

5. call() returns:

   success = false

6. Because the contract never executes:

   require(success)

   execution continues normally.

7. The transaction succeeds even though the external call failed.

This demonstrates a silent failure.

Root Cause:

The developer uses Solidity's low-level call() without validating the
returned success boolean.

Low-level calls do not automatically revert on failure.

Failure handling must be implemented explicitly by checking the success
value.

Recommendation:

Always validate the success value returned by every low-level call.

Recommended mitigations include:

- execute require(success) immediately after call()
- revert the transaction when external calls fail
- follow the Checks-Effects-Interactions (CEI) pattern
- use higher-level interface calls when possible
- emit events for failed external interactions if appropriate
- avoid ignoring returned values from call(), delegatecall(), staticcall(),
  and send()

Patched Code Example:

(bool success, bytes memory data) =
    target.call(
        abi.encodeWithSignature("successFunction()")
    );

lastSuccess = success;
lastData = data;

require(success, "External function call failed");

*/

// Patched code
contract CallTarget {

    uint256 public counter;

    function successFunction() external {
        counter++;
    }

    function failFunction() external pure {
        revert("Intentional failure");
    }

    receive() external payable {
        revert("ETH rejected");
    }
}

contract SafeCallHandler {

    bool public lastSuccess;
    bytes public lastData;
    uint256 public executionCounter;

    /*
    =====================================================
    SAFE FUNCTION CALL
    =====================================================
    */

    function safeFunctionCall(address target) external {

        executionCounter++;

        (bool success, bytes memory data) =
            target.call(
                abi.encodeWithSignature(
                    "successFunction()"
                )
            );

        lastSuccess = success;
        lastData = data;

        // Check return value
        require(success, "External function call failed");
    }

    /*
    =====================================================
    SAFE FAILING CALL
    =====================================================
    */

    function safeFailingCall(address target) external {

        executionCounter++;

        (bool success, bytes memory data) =
            target.call(
                abi.encodeWithSignature(
                    "failFunction()"
                )
            );

        lastSuccess = success;
        lastData = data;

        // Revert if call failed
        require(success, "External call reverted");
    }

    /*
    =====================================================
    SAFE ETH TRANSFER
    =====================================================
    */

    function safeETHTransfer(
        address payable target
    )
        external
        payable
    {
        (bool success, bytes memory data) =
            target.call{value: msg.value}("");

        lastSuccess = success;
        lastData = data;

        // Prevent silent failure
        require(success, "ETH transfer failed");
    }
}