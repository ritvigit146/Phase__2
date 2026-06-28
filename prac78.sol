// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Fix Reentrancy using CEI Pattern
CONCEPT: Secure execution order
=========================================================

OBJECTIVE

- Fix reentrancy vulnerability
- Apply Checks → Effects → Interactions pattern
- Ensure secure ETH withdrawal flow
- Prevent recursive external calls exploitation

---------------------------------------------------------
CORE IDEA (CEI PATTERN)
---------------------------------------------------------

✔ CHECKS        → validate conditions
✔ EFFECTS       → update state FIRST
✔ INTERACTIONS  → external calls LAST

---------------------------------------------------------

This prevents reentrancy because:

state is already updated
before external contract can re-enter

=========================================================
SECURE BANK CONTRACT
=========================================================
*/
contract VulnerableBank {

    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    /*
    =====================================================
    VULNERABLE WITHDRAW
    =====================================================
    */

    function withdraw(uint256 amount) external {

        require(balance[msg.sender] >= amount, "Insufficient balance");

        // Interaction before Effects
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State updated after external call
        balance[msg.sender] -= amount;
    }

    function getBalance(address user)
        external
        view
        returns (uint256)
    {
        return balance[user];
    }
}
/*
Audit Report

Title: Reentrancy Vulnerability in withdraw()

Severity: High because an attacker can repeatedly withdraw funds before
their balance is updated, potentially draining the contract.

Location:
Contract: VulnerableBank
Function: withdraw(uint256)

Vulnerability Description:
The withdraw() function performs an external call to msg.sender before
updating the user's balance.

Since control is transferred to an untrusted external contract first,
a malicious contract can execute its fallback() function and re-enter
withdraw() multiple times while its recorded balance remains unchanged.

This violates the Checks-Effects-Interactions (CEI) pattern and enables
a classic reentrancy attack.

Impact:
An attacker can recursively call withdraw() and drain ETH from the
contract, resulting in loss of user funds and protocol insolvency.

Proof of Concept:

1. Deploy VulnerableBank.
2. Deposit ETH from multiple users.
3. Deploy ReentrancyAttacker with the bank's address.
4. Call attack() with 1 ETH.
5. The attacker deposits 1 ETH into the bank.
6. The attacker calls withdraw(1 ether).
7. During the ETH transfer, the attacker's fallback() function executes.
8. The fallback() function re-enters withdraw() before the balance is updated.
9. This process repeats until the bank no longer has sufficient ETH.

Root Cause:
The contract performs an external call before updating internal state.

Vulnerable code:

(bool success, ) = msg.sender.call{value: amount}("");
require(success, "Transfer failed");

balance[msg.sender] -= amount;

This execution order allows reentrant calls before the user's balance
is reduced.

Recommendation:
Follow the Checks-Effects-Interactions (CEI) pattern by updating the
user's balance before making any external call.
*/

// Patched code
contract SecureBank {

    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    /*
    =====================================================
    SECURE WITHDRAW
    =====================================================
    */

    function withdraw(uint256 amount) external {

        // Checks
        require(balance[msg.sender] >= amount, "Insufficient balance");

        // Effects
        balance[msg.sender] -= amount;

        // Interaction
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getBalance(address user)
        external
        view
        returns (uint256)
    {
        return balance[user];
    }
}