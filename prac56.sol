// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call malicious contract
CONCEPT: Attack surface
=========================================================

OBJECTIVE

- Learn dangers of external contract calls
- Understand malicious-contract behavior
- Learn reentrancy attack surface
- Think like attacker + auditor

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Every external contract call is:
UNTRUSTED EXECUTION.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

When your contract calls another contract:

CONTROL temporarily leaves your contract.

---------------------------------------------------------

The called contract may:
- revert
- reenter
- consume gas
- manipulate logic
- attack state assumptions

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most major Solidity hacks involve:

external contract interactions.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

External calls occur in:

- ERC20 interactions
- swaps
- lending
- bridges
- staking
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- reentrancy windows
- trust assumptions
- call ordering
- arbitrary external execution
- unchecked return values

=========================================================
VICTIM CONTRACT
=========================================================
*/
contract VictimBankVul {

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        balances[msg.sender] += msg.value;
    }

    /*
        VULNERABLE:
        External call before state update.
    */
    function withdraw(
        uint256 _amount
    )
        external
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        // Interaction first
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        // Effects later
        balances[msg.sender] -= _amount;
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
ATTACK FLOW
=========================================================

STEP 1:
Deploy VictimBank

---------------------------------------------------------

STEP 2:
Fund VictimBank with ETH

=========================================================
STEP 3
=========================================================

Deploy MaliciousAttacker

Constructor input:
VictimBank address

=========================================================
STEP 4
=========================================================

Call:
depositToVictim()

VALUE:
1 ETH

---------------------------------------------------------

Attacker now has:
1 ETH balance in victim.

=========================================================
STEP 5
=========================================================

Call:
attack()

---------------------------------------------------------

Execution enters:

victim.vulnerableWithdraw()

=========================================================
CRITICAL VULNERABILITY
=========================================================

Victim executes:

call{value: 1 ether}()

BEFORE reducing balance.

---------------------------------------------------------

CONTROL transfers to:
MaliciousAttacker.receive()

=========================================================
INSIDE ATTACKER receive()
=========================================================

receive() executes automatically.

---------------------------------------------------------

Attacker checks:

victim still has ETH?

---------------------------------------------------------

YES

---------------------------------------------------------

Attacker REENTERS:

victim.vulnerableWithdraw()

=========================================================
IMPORTANT
=========================================================

Victim storage NOT updated yet.

---------------------------------------------------------

balances[attacker]
still unchanged.

---------------------------------------------------------

Attacker withdraws repeatedly.

=========================================================
FINAL RESULT
=========================================================

Attacker drains victim ETH.

=========================================================
WHY THIS HAPPENS
=========================================================

BAD ORDER:

interaction BEFORE effects.

---------------------------------------------------------

Classic reentrancy vulnerability.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy VictimBank

---------------------------------------------------------

STEP 2:
Deposit multiple ETH into victim

---------------------------------------------------------

STEP 3:
Deploy MaliciousAttacker

Input:
VictimBank address

---------------------------------------------------------

STEP 4:
Call:
depositToVictim()

VALUE:
1 ETH

---------------------------------------------------------

STEP 5:
Call:
attack()

---------------------------------------------------------

STEP 6:
Observe:

Victim ETH decreases heavily.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
Multiple attack rounds

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External contracts are:
UNTRUSTED.

---------------------------------------------------------

Never assume:
called contracts behave safely.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

Most famous Solidity vulnerability.

---------------------------------------------------------
2. ARBITRARY EXECUTION
---------------------------------------------------------

External contracts control execution flow.

---------------------------------------------------------
3. DOS VIA REVERT
---------------------------------------------------------

Malicious contract may always revert.

---------------------------------------------------------
4. GAS GRIEFING
---------------------------------------------------------

Malicious contract consumes excessive gas.

=========================================================
CHECKS-EFFECTS-INTERACTIONS
=========================================================

SAFE PATTERN:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

safeWithdraw() follows this correctly.

=========================================================
VERY IMPORTANT AUDITOR MINDSET
=========================================================

Auditors NEVER trust:
external contracts.

---------------------------------------------------------

Every external interaction =
potential attack surface.

=========================================================
ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- state updates after calls
- reentrancy windows
- unchecked return values

---------------------------------------------------------

Then:
build malicious contracts to exploit.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interaction timing
2. Storage update order
3. Reentrancy possibilities
4. ETH transfer behavior
5. Cross-contract execution flow

=========================================================
MINI CHALLENGE
=========================================================

Modify VictimBank so that:

1. Add nonReentrant modifier
2. Block reentrancy attack
3. Add event logging
4. Compare safe vs vulnerable execution

BONUS:
Create ERC20-style malicious token attack.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External contracts are untrusted
- call() transfers execution control
- Reentrancy exploits bad ordering
- receive()/fallback() can attack automatically
- CEI pattern improves security
- External calls create attack surface
- Malicious contracts manipulate execution flow
- Auditors inspect every external interaction
- Reentrancy is one of Solidity's biggest risks
- Cross-contract execution is security critical

=========================================================
*/
/*
Audit Report

Title: Reentrancy Vulnerability in vulnerableWithdraw()

Severity: High because an attacker can repeatedly
withdraw ETH before their balance is updated,
resulting in theft of contract funds.

Location:
Contract: VictimBank
Function: vulnerableWithdraw()

Vulnerability Description:

The vulnerableWithdraw() function performs an
external ETH transfer using call() before updating
the user's balance.

Because control is transferred to an untrusted
external contract before state changes occur,
a malicious contract can re-enter the function
through its receive() or fallback() function.

Since the balance has not yet been reduced,
multiple withdrawals can occur during a single
transaction.

Impact:

An attacker can drain all ETH stored in the contract.

Potential consequences include:

- theft of user funds
- complete contract balance drain
- protocol insolvency
- denial of service for legitimate users

Proof of Concept:

1. Deploy VictimBank

2. Fund VictimBank with multiple ETH

3. Deploy MaliciousAttacker

4. Deposit 1 ETH through:

       depositToVictim()

5. Call:

       attack()

6. Victim executes:

       vulnerableWithdraw(1 ether)

7. ETH is sent to attacker before
   balance reduction occurs

8. Attacker's receive() function executes

9. Attacker re-enters:

       vulnerableWithdraw(1 ether)

10. Process repeats until available ETH
    is drained from the contract

Root Cause:

The function violates the
Checks-Effects-Interactions (CEI) pattern.

External interaction occurs before state update.

Vulnerable code:

    (bool success, ) =
        payable(msg.sender).call{
            value: _amount
        }("");

    require(
        success,
        "Transfer failed"
    );

    balances[msg.sender] -= _amount;

Recommendation:

Update state before performing external calls.

Example:

    balances[msg.sender] -= _amount;

    (bool success, ) =
        payable(msg.sender).call{
            value: _amount
        }("");

    require(
        success,
        "Transfer failed"
    );

Additionally, implement a reentrancy guard.

Example:

    modifier nonReentrant() {
        ...
    }

Status:

Fixed in patched implementation.

*/

// Patched code
contract VictimBank {

    mapping(address => uint256) public balances;

    bool private locked;

    modifier nonReentrant() {
        require(
            !locked,
            "Reentrancy blocked"
        );

        locked = true;
        _;
        locked = false;
    }

    function deposit()
        external
        payable
    {
        balances[msg.sender] += msg.value;
    }

    /*
        PATCHED:
        State updated before external call.
        Reentrancy guard added.
    */
    function withdraw(
        uint256 _amount
    )
        external
        nonReentrant
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        // Effects
        balances[msg.sender] -= _amount;

        // Interaction
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );
    }

    function contractBalance()
        external
        view
        returns (uint256)
    {
        return address(this).balance;
    }
}