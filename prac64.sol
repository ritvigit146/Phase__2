// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH to non-payable contract
CONCEPT: Revert behavior
=========================================================

OBJECTIVE

- Learn why ETH transfers may fail
- Understand payable vs non-payable behavior
- Learn revert propagation mechanics
- Understand safe ETH transfer handling

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

A contract CANNOT receive ETH unless:

- receive() exists
OR
- fallback() is payable
OR
- target function is payable

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Sending ETH to a non-payable contract:

REVERTS the transaction.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH transfer assumptions cause:

- failed withdrawals
- stuck funds
- broken integrations
- DOS vulnerabilities

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

ETH transfer logic exists in:

- vaults
- bridges
- staking systems
- exchanges
- DAO treasuries
- payment protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- payable correctness
- ETH acceptance logic
- transfer failure handling
- unchecked call results
- DOS possibilities

=========================================================
NON-PAYABLE CONTRACT
=========================================================
*/
contract NonPayableReceiverVul {

    uint256 public counter;

    function increment() external {
        counter++;
    }

    // No receive() or payable fallback()
}

contract ETHSenderVul {

    bool public lastSuccess;
    uint256 public totalSent;

    /*
    =====================================================
    VULNERABLE FUNCTION
    =====================================================

    The return value of call() is ignored.
    */

    function dangerousSend(
        address payable _receiver
    )
        external
        payable
    {
        // ETH transfer attempted
        _receiver.call{value: msg.value}("");

        // VULNERABILITY:
        // Execution continues even if transfer failed.

        totalSent += msg.value;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy NonPayableReceiver

---------------------------------------------------------

STEP 2:
Deploy PayableReceiver

---------------------------------------------------------

STEP 3:
Deploy ETHSender

=========================================================
TRACE:
sendETH() TO NON-PAYABLE CONTRACT
=========================================================

STEP 1:
User calls:

sendETH()

---------------------------------------------------------

VALUE:
1 ETH

---------------------------------------------------------

Receiver:
NonPayableReceiver

=========================================================
STEP 2
=========================================================

Low-level call executes:

_receiver.call{value: 1 ether}("")

=========================================================
STEP 3
=========================================================

Ethereum attempts to send ETH.

=========================================================
IMPORTANT
=========================================================

Target contract has:

---------------------------------------------------------
NO receive()
---------------------------------------------------------

AND

---------------------------------------------------------
NO payable fallback()
---------------------------------------------------------

=========================================================
STEP 4
=========================================================

ETH transfer automatically fails.

---------------------------------------------------------

success = false

=========================================================
STEP 5
=========================================================

require(success)

---------------------------------------------------------

FAILS

---------------------------------------------------------

FULL TRANSACTION REVERTS

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
ETH transferred?
---------------------------------------------------------

NO

---------------------------------------------------------
totalSent updated?
---------------------------------------------------------

NO

---------------------------------------------------------
Transaction status?
---------------------------------------------------------

REVERTED

=========================================================
WHY?
=========================================================

Contract cannot accept ETH.

=========================================================
TRACE:
sendETH() TO PAYABLE CONTRACT
=========================================================

STEP 1:
Call:
sendETH()

---------------------------------------------------------

VALUE:
1 ETH

---------------------------------------------------------

Receiver:
PayableReceiver

=========================================================
STEP 2
=========================================================

receive() executes successfully.

---------------------------------------------------------

success = true

=========================================================
STEP 3
=========================================================

require(success)

---------------------------------------------------------

PASSES

=========================================================
STEP 4
=========================================================

totalSent += 1 ether

=========================================================
FINAL RESULT
=========================================================

ETH transfer succeeds safely.

=========================================================
DANGEROUS TRACE
=========================================================

CALL:
dangerousSend()

---------------------------------------------------------

Receiver:
NonPayableReceiver

=========================================================

STEP 1:
ETH transfer fails.

---------------------------------------------------------

success = false

=========================================================
STEP 2
=========================================================

IMPORTANT:

success ignored completely.

=========================================================
STEP 3
=========================================================

Execution continues.

---------------------------------------------------------

totalSent += msg.value

=========================================================
CRITICAL PROBLEM
=========================================================

Internal accounting says:
ETH sent.

---------------------------------------------------------

Reality:
ETH transfer FAILED.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy NonPayableReceiver

---------------------------------------------------------

STEP 2:
Deploy PayableReceiver

---------------------------------------------------------

STEP 3:
Deploy ETHSender

=========================================================
TEST 1
=========================================================

Call:
sendETH()

---------------------------------------------------------

Receiver:
NonPayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Transaction reverts

=========================================================
TEST 2
=========================================================

Call:
sendETH()

---------------------------------------------------------

Receiver:
PayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Success

=========================================================
TEST 3
=========================================================

Call:
dangerousSend()

---------------------------------------------------------

Receiver:
NonPayableReceiver address

---------------------------------------------------------

VALUE:
1 ether

---------------------------------------------------------

EXPECTED:
Transaction succeeds incorrectly

=========================================================
STEP 4
=========================================================

Check:
totalSent()

---------------------------------------------------------

IMPORTANT:
Accounting corrupted.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

ETH transfers are NOT guaranteed.

---------------------------------------------------------

Receiving contracts control acceptance behavior.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. UNCHECKED ETH TRANSFERS
---------------------------------------------------------

Silent failures corrupt logic.

---------------------------------------------------------
2. NON-PAYABLE TARGETS
---------------------------------------------------------

Unexpected revert conditions.

---------------------------------------------------------
3. DOS VIA REVERT
---------------------------------------------------------

Malicious contracts reject ETH intentionally.

---------------------------------------------------------
4. ACCOUNTING INCONSISTENCY
---------------------------------------------------------

Protocol state diverges from reality.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers may:

- reject ETH intentionally
- revert receive()
- break protocol assumptions
- trigger DOS conditions

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can target receive ETH?
- Is success checked?
- Are failures handled safely?
- Can ETH rejection DOS protocol?
- Is accounting updated correctly?

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH transfer behavior
2. Payable correctness
3. Failure propagation
4. Accounting consistency
5. External trust assumptions

=========================================================
BEST PRACTICE
=========================================================

Always:

---------------------------------------------------------
(bool success, ) = receiver.call{value: x}("");

require(success)
---------------------------------------------------------

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add payable fallback()
2. Add try/catch handling
3. Add event logging
4. Compare transfer/send/call

BONUS:
Create malicious ETH-rejecting DOS contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Non-payable contracts reject ETH
- ETH transfers may revert
- receive() enables ETH reception
- call() returns success manually
- Ignoring success is dangerous
- External ETH handling is untrusted
- Reverts rollback transaction state
- Accounting must follow successful transfers
- Auditors inspect ETH-transfer assumptions
- Safe ETH handling is critical in Solidity

=========================================================
*/
/*
Audit Report

Title: Unchecked Return Value of Low-Level ETH Transfer

Severity: Medium because the contract updates its internal accounting
even when the ETH transfer fails, resulting in inconsistent protocol state.

Location: Contract: ETHSenderVul
Function: dangerousSend()

Vulnerability Description:

The dangerousSend() function performs a low-level ETH transfer using
call{value: msg.value}("") but ignores the returned success value.

If the recipient contract rejects the ETH transfer (for example, because
it does not implement a receive() function or has a non-payable fallback()),
the call returns false instead of reverting.

Since the return value is ignored, execution continues and totalSent is
updated even though the ETH transfer never occurred.

Impact:

An attacker can intentionally send ETH to a contract that cannot receive ETH,
causing the transfer to fail while the sender contract records it as
successful.

This may result in:

- Incorrect accounting
- False payment records
- Inconsistent contract state
- Broken protocol logic
- Potential financial losses if other functions rely on totalSent

Proof of Concept:

1. Deploy NonPayableReceiver.
2. Deploy ETHSenderVul.
3. Call:

    dangerousSend(NonPayableReceiver)

   with 1 ETH.

4. The low-level call fails because the receiver cannot accept ETH.
5. The success value is ignored.
6. Execution continues normally.
7. totalSent increases by 1 ETH.
8. The ETH remains in ETHSenderVul.
9. Internal accounting incorrectly indicates that the transfer succeeded.

Root Cause:

The function ignores the boolean success value returned by the low-level
call() operation and assumes the ETH transfer was successful.

Recommendation:

Always verify the success value returned by low-level calls before updating
contract state.

Example:

(bool success, ) = _receiver.call{value: msg.value}("");

require(success, "ETH transfer failed");

totalSent += msg.value;

This ensures that accounting is only updated after a successful ETH transfer.

*/

// Patched code
contract PayableReceiver {

    uint256 public receivedAmount;

    receive() external payable {
        receivedAmount += msg.value;
    }
}

contract ETHSenderPatched {

    bool public lastSuccess;
    uint256 public totalSent;

    /*
    =====================================================
    SECURE FUNCTION
    =====================================================
    */

    function safeSend(
        address payable _receiver
    )
        external
        payable
    {
        (bool success, ) = _receiver.call{value: msg.value}("");

        lastSuccess = success;

        require(success, "ETH transfer failed");

        // Accounting updated only after successful transfer
        totalSent += msg.value;
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}