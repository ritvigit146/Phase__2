// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: tx.origin Authentication Contract
CONCEPT: Dangerous authentication pattern
=========================================================

WARNING:
This contract demonstrates a BAD PRACTICE.

DO NOT use tx.origin for authentication in production.
=========================================================
*/
contract TxOriginAuthVul {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    VULNERABLE AUTHENTICATION
    =====================================================
    */

    function withdrawAll() external {

        //  Vulnerable: Authentication using tx.origin
        require(tx.origin == owner, "Not owner");

        payable(owner).transfer(address(this).balance);
    }

    function deposit() external payable {}
}
/*
Audit Report

Title: Use of tx.origin for Authentication

Severity: High because an attacker can bypass the intended access control
by tricking the contract owner into interacting with a malicious contract.

Location:
Contract: TxOriginAuth
Function: withdrawAll()

Vulnerability Description:
The withdrawAll() function uses `tx.origin` to authenticate the caller.

require(tx.origin == owner, "Not owner");

The tx.origin variable returns the original externally owned account (EOA)
that initiated the transaction, regardless of how many contracts are called
along the execution path.

If the owner is tricked into interacting with a malicious contract, that
contract can invoke withdrawAll() on behalf of the owner. Since `tx.origin`
remains the owner's address throughout the transaction, the authorization
check succeeds even though the immediate caller (`msg.sender`) is the
malicious contract.

Impact:
An attacker can bypass the intended authorization mechanism and trigger
privileged functions by exploiting the owner's transaction.

This may result in:

* Unauthorized execution of privileged functions
* Theft of contract funds
* Loss of protocol security
* Phishing-based privilege escalation

Proof of Concept:

1. Deploy TxOriginAuth.
2. Deposit ETH into the contract.
3. Deploy a malicious contract containing a function that calls
   TxOriginAuth.withdrawAll().
4. Convince the owner to call the malicious contract.
5. The malicious contract calls withdrawAll().
6. tx.origin equals the owner's address, so the authorization check passes.
7. The privileged function executes even though `msg.sender` is the attack contract.

Root Cause:
The contract relies on tx.origin for access control.

tx.origin identifies the original transaction initiator rather than the immediate caller. Authorization decisions should always 
be based on msg.sender, which represents the direct caller of the function.

Recommendation:
Replace the tx.origin authentication check with msg.sender

Example:
require(msg.sender == owner, "Not owner");

Using msg.sender ensures that only the authorized account can directly invoke privileged functions and prevents phishing 
attacks that exploit tx.origin

*/

// Patched code
contract TxOriginAuthPatched {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /*
    =====================================================
    SECURE AUTHENTICATION
    =====================================================
    */

    function withdrawAll() external {

        // Secure: Authenticate using msg.sender
        require(msg.sender == owner, "Not owner");

        payable(owner).transfer(address(this).balance);
    }

    function deposit() external payable {}
}