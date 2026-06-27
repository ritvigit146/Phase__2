// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Ignore success boolean from call
CONCEPT: Dangerous coding
=========================================================

OBJECTIVE

- Learn why unchecked call() is dangerous
- Understand silent external-call failures
- Learn inconsistent state vulnerabilities
- Think like professional auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Low-level call() returns:

(bool success, bytes memory data)

---------------------------------------------------------

If success is ignored:

execution may continue
even when external call FAILED.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

This creates:
silent failure vulnerabilities.

---------------------------------------------------------

Protocol may assume:
external interaction succeeded.

---------------------------------------------------------

Reality:
it failed completely.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Unchecked external calls caused:

- stuck funds
- accounting corruption
- broken logic
- DOS vulnerabilities
- protocol inconsistencies

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls exist in:

- token transfers
- swaps
- governance execution
- vault withdrawals
- bridges
- staking systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors ALWAYS inspect:

- ignored success booleans
- unchecked external calls
- silent failures
- accounting assumptions
- inconsistent state

=========================================================
MALICIOUS / FAILING CONTRACT
=========================================================
*/
contract RejectETH {

    uint256 public counter;

    receive() external payable {
        revert("ETH rejected");
    }

    function failFunction() external pure {
        revert("Function failed");
    }

    function successFunction() external {
        counter++;
    }
}

contract DangerousUncheckedCallVul {

    mapping(address => uint256) public balances;

    mapping(address => bool) public withdrawn;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    /*
        VULNERABILITY:
        Ignores success boolean returned by call()
    */
    function dangerousWithdraw(
        address payable _receiver,
        uint256 _amount
    ) external {

        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        balances[msg.sender] -= _amount;

        withdrawn[msg.sender] = true;

        // Vulnerable external call
        (bool success, ) = _receiver.call{value: _amount}("");

// Intentionally ignore success
success;

        /*
            If ETH transfer fails:

            success = false

            But execution continues.

            State remains changed even though
            ETH was never transferred.
        */
    }

    function contractBalance()
        external
        view
        returns(uint256)
    {
        return address(this).balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy RejectETH

---------------------------------------------------------

STEP 2:
Deploy DangerousUncheckedCall

=========================================================
TRACE:
dangerousWithdraw()
=========================================================

STEP 1:
User deposits ETH.

---------------------------------------------------------

balances[user] = 1 ETH

=========================================================
STEP 2
=========================================================

Call:
dangerousWithdraw()

---------------------------------------------------------

Receiver:
RejectETH contract

=========================================================
STEP 3
=========================================================

Balance validation passes.

=========================================================
STEP 4
=========================================================

Storage updated FIRST.

---------------------------------------------------------

balances[user] -= 1 ETH

---------------------------------------------------------

withdrawn[user] = true

=========================================================
STEP 5
=========================================================

External ETH call executes.

---------------------------------------------------------

Receiver contract:
REVERTS intentionally.

=========================================================
STEP 6
=========================================================

IMPORTANT:

call() returns:

success = false

---------------------------------------------------------

BUT:

success is IGNORED.

=========================================================
STEP 7
=========================================================

Execution continues normally.

---------------------------------------------------------

Transaction DOES NOT revert.

=========================================================
FINAL RESULT
=========================================================

PROBLEM:

---------------------------------------------------------
USER BALANCE REDUCED
---------------------------------------------------------

YES

---------------------------------------------------------
withdrawn FLAG SET
---------------------------------------------------------

YES

---------------------------------------------------------
ETH ACTUALLY TRANSFERRED?
---------------------------------------------------------

NO

=========================================================
CRITICAL VULNERABILITY
=========================================================

Internal accounting says:
withdraw succeeded.

---------------------------------------------------------

Reality:
ETH never transferred.

=========================================================
WHY THIS IS DANGEROUS
=========================================================

Creates:
INCONSISTENT STATE.

---------------------------------------------------------

Protocol assumptions become false.

=========================================================
SAFE VERSION TRACE
=========================================================

safeWithdraw()

=========================================================

STEP 1:
External call fails.

---------------------------------------------------------

success = false

=========================================================
STEP 2
=========================================================

require(success)

---------------------------------------------------------

Transaction REVERTS.

=========================================================
STEP 3
=========================================================

ALL state changes rollback.

---------------------------------------------------------

balances restored.

---------------------------------------------------------

No inconsistent state.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy RejectETH

---------------------------------------------------------

STEP 2:
Deploy DangerousUncheckedCall

---------------------------------------------------------

STEP 3:
Deposit 1 ETH

---------------------------------------------------------

STEP 4:
Call:
dangerousWithdraw()

Inputs:
- RejectETH address
- 1 ether

---------------------------------------------------------

EXPECTED:
Transaction succeeds unexpectedly.

=========================================================
STEP 5
=========================================================

Check:

balances(user)

EXPECTED:
0

---------------------------------------------------------

withdrawn(user)

EXPECTED:
true

---------------------------------------------------------

BUT:
RejectETH received NO ETH.

=========================================================
STEP 6
=========================================================

Test:
safeWithdraw()

---------------------------------------------------------

EXPECTED:
Transaction reverts safely.

=========================================================
IMPORTANT LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() NEVER auto-reverts.

---------------------------------------------------------

Developer MUST manually check:

success

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED RETURN VALUES
---------------------------------------------------------

Classic Solidity vulnerability.

---------------------------------------------------------
2. ACCOUNTING CORRUPTION
---------------------------------------------------------

Internal state diverges from reality.

---------------------------------------------------------
3. SILENT FAILURES
---------------------------------------------------------

Protocol believes operation succeeded.

---------------------------------------------------------
4. DOS CONDITIONS
---------------------------------------------------------

Malicious contracts block execution silently.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External calls are:
UNTRUSTED INTERACTIONS.

---------------------------------------------------------

Assume:
external execution may fail.

=========================================================
ATTACK THINKING
=========================================================

Attacker intentionally:

- rejects ETH
- reverts calls
- breaks assumptions
- causes inconsistent state

---------------------------------------------------------

Protocol logic becomes corrupted.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ALWAYS search for:

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

1. External interaction
2. Failure handling
3. Return-value checks
4. Accounting consistency
5. Silent-failure paths

=========================================================
WHY THIS BUG IS SUBTLE
=========================================================

Transaction appears:
successful.

---------------------------------------------------------

But:
protocol state corrupted internally.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add event logging
2. Add try/catch handling
3. Add revert-message decoding
4. Compare checked vs unchecked execution

BONUS:
Create token-transfer version
of unchecked-call bug.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- call() returns success manually
- Ignoring success is dangerous
- External calls may silently fail
- Silent failures corrupt accounting
- Transactions only revert if forced
- require(success) prevents inconsistencies
- Unchecked calls are major audit issue
- External interactions are untrusted
- Auditors inspect return-value handling carefully
- Error handling is critical in Solidity security

=========================================================
*/
/*
Audit Report

Title: Unchecked Return Value of Low-Level Call

Severity: High because failed ETH transfers can be ignored,
causing accounting inconsistencies and potential loss of funds.

Location:
Contract: DangerousUncheckedCall
Function: dangerousWithdraw()

Vulnerability Description:

The dangerousWithdraw() function performs a low-level ETH transfer
using:

    _receiver.call{value: _amount}("");

However, the returned success boolean is completely ignored.

Low-level call() never automatically reverts on failure.

Instead it returns:

    (bool success, bytes memory data)

If the receiver contract rejects ETH or reverts,
success becomes false.

Since the function does not check this value,
execution continues normally and previously updated
state variables remain modified.

As a result, the contract records the withdrawal as
successful even though no ETH was transferred.

Impact:

- User balance decreases
- withdrawn flag becomes true
- ETH transfer may fail
- Internal accounting becomes inconsistent
- Funds can become stuck inside the contract
- Protocol state diverges from actual asset movement

Proof of Concept:

1. Deploy RejectETH contract

2. Deploy DangerousUncheckedCall contract

3. User deposits 1 ETH

    deposit()
    Value = 1 ETH

4. User calls:

    dangerousWithdraw(
        rejectETHAddress,
        1 ether
    )

5. Contract executes:

    balances[msg.sender] -= 1 ether;

    withdrawn[msg.sender] = true;

6. External call executes:

    _receiver.call{value: 1 ether}("");

7. RejectETH receive() function reverts:

    revert("ETH rejected");

8. call() returns:

    success = false

9. Success value is ignored

10. Transaction completes successfully

11. Final state:

    balances[user] = 0

    withdrawn[user] = true

12. RejectETH balance:

    0 ETH

13. DangerousUncheckedCall still holds the ETH

Root Cause:

The developer failed to validate the return value
of the low-level call.

The code assumes the transfer succeeded without checking:

    bool success

This creates a silent failure condition where
contract state no longer reflects reality.

Vulnerable Code:

    _receiver.call{value: _amount}("");

Recommendation:

Always validate the return value of low-level calls.

Example:

    (bool success, ) =
        _receiver.call{value: _amount}("");

    require(
        success,
        "ETH transfer failed"
    );

This ensures that failed transfers revert the
entire transaction and restore all state changes.

*/

// Patched code
contract DangerousUncheckedCallPatched {

    mapping(address => uint256) public balances;

    mapping(address => bool) public withdrawn;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function safeWithdraw(
        address payable _receiver,
        uint256 _amount
    ) external {

        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        (bool success, ) =
            _receiver.call{value: _amount}("");

        require(
            success,
            "ETH transfer failed"
        );

        balances[msg.sender] -= _amount;

        withdrawn[msg.sender] = true;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}