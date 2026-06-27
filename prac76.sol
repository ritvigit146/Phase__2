// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Vulnerable Reentrancy Bank
CONCEPT: Root reentrancy logic
=========================================================

WARNING:
This contract is INTENTIONALLY VULNERABLE.

DO NOT use in production.
=========================================================
*/
contract VulnerableBank {

    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    // VULNERABLE TO REENTRANCY
    function withdraw(uint256 amount) external {

        require(balance[msg.sender] >= amount, "Not enough balance");

        // External call before state update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State updated too late
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

Severity: High because an attacker can repeatedly withdraw funds before their balance is updated, potentially draining all 
Ether held by the contract.

Location:
Contract: VulnerableBank
Function: withdraw(uint256 amount)

Vulnerability Description:
The withdraw() function performs an external call to msg.sender before updating
the user's balance.

Since control is transferred to an untrusted external address before the contract's
internal state is updated, a malicious contract can re-enter withdraw() through
its receive() or fallback() function.

Because the balance is not reduced until after the external call returns,
each reentrant call passes the balance check and allows multiple withdrawals
using the same deposited balance.

Impact:
An attacker can recursively call withdraw() and drain all Ether stored in the
contract, including funds belonging to other users.

This can lead to:
- complete loss of contract funds
- theft of user deposits
- protocol insolvency
- denial of service for legitimate users

Proof of Concept:

1. Deploy VulnerableBank.
2. Deposit 1 ETH from a malicious attacker contract.
3. Call withdraw(1 ether).
4. The contract sends 1 ETH to the attacker.
5. The attacker's receive() function immediately calls withdraw(1 ether) again.
6. Since the balance has not yet been decreased, the balance check succeeds.
7. The process repeats until the contract's Ether balance is drained.
8. Only after the recursive calls finish is the attacker's balance reduced once.

Root Cause:
The function violates the Checks-Effects-Interactions (CEI) pattern by making
an external call before updating internal state.

Specifically:

(bool success, ) = msg.sender.call{value: amount}("");
require(success, "Transfer failed");

balance[msg.sender] -= amount;

The balance update occurs after the external interaction, allowing reentrant
execution before the state is changed.

Recommendation:
Follow the Checks-Effects-Interactions (CEI) pattern by updating the user's
balance before making the external call.

Example:

require(balance[msg.sender] >= amount, "Not enough balance");

balance[msg.sender] -= amount;

(bool success, ) = msg.sender.call{value: amount}("");
require(success, "Transfer failed");

Additionally, use OpenZeppelin's ReentrancyGuard and apply the nonReentrant
modifier to the withdraw() function for defense in depth.

*/

// Patched code
contract PatchedBank {

    mapping(address => uint256) public balance;

    function deposit() external payable {
        balance[msg.sender] += msg.value;
    }

    // SAFE AGAINST REENTRANCY
    function withdraw(uint256 amount) external {

        require(balance[msg.sender] >= amount, "Not enough balance");

        // Update state first
        balance[msg.sender] -= amount;

        // External interaction after state update
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