// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH using transfer
CONCEPT: ETH transfer mechanics
=========================================================

OBJECTIVE

- Learn how transfer() sends ETH
- Understand native ETH movement
- Learn payable mechanics
- Understand transfer limitations + risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

transfer() sends native ETH
from one contract/address to another.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

ETH transfers:
trigger external execution.

---------------------------------------------------------

Receiving contracts may execute:
receive() or fallback().

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

ETH transfers are fundamental to:

- withdrawals
- payments
- staking
- refunds
- treasury systems
- DeFi protocols

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

ETH transfer logic used in:

- exchanges
- vaults
- DAOs
- staking systems
- NFT marketplaces
- lending protocols

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- transfer ordering
- reentrancy risk
- failed transfer handling
- locked ETH risks
- DOS vectors

=========================================================
*/
contract EthTransferMechanicsVul {

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "No ETH sent"
        );

        balances[msg.sender] += msg.value;
    }

    /*
        VULNERABLE:
        External call occurs before
        state update.
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

        /*
            INTERACTION FIRST
            Dangerous.
        */
        (bool success, ) =
            payable(msg.sender).call{value: _amount}("");

        require(
            success,
            "Transfer failed"
        );

        /*
            EFFECTS AFTER INTERACTION

            Attacker can reenter before
            this executes.
        */
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
EXECUTION FLOW
=========================================================

STEP 1:
User deposits ETH.

---------------------------------------------------------

CALL:
deposit()

VALUE:
1 ETH

=========================================================
DEPOSIT TRACE
=========================================================

STEP 1:
Transaction carries ETH.

---------------------------------------------------------

msg.value = 1 ETH

---------------------------------------------------------

STEP 2:
require(msg.value > 0)

RESULT:
true

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 1 ETH

---------------------------------------------------------

STEP 4:
Contract receives ETH.

---------------------------------------------------------

CONTRACT BALANCE:
1 ETH

=========================================================
WITHDRAW TRACE
=========================================================

CALL:
withdraw(1 ETH)

=========================================================

STEP 1:
Balance validation.

---------------------------------------------------------

balances[Alice] >= 1 ETH

RESULT:
true

---------------------------------------------------------
STEP 2:
Storage updated FIRST.

balances[Alice] -= 1 ETH

---------------------------------------------------------

NEW VALUE:
0

---------------------------------------------------------
STEP 3:
ETH transfer executes.

payable(msg.sender).transfer(1 ETH)

---------------------------------------------------------

ETH leaves contract.

---------------------------------------------------------

Alice receives ETH.

=========================================================
IMPORTANT transfer() UNDERSTANDING
=========================================================

transfer():

- sends native ETH
- forwards ONLY 2300 gas
- auto-reverts on failure

=========================================================
VERY IMPORTANT:
2300 GAS LIMIT
=========================================================

Receiving contract gets:

ONLY 2300 gas

---------------------------------------------------------

This usually prevents:
complex execution.

---------------------------------------------------------

Historically helped reduce:
reentrancy risk.

=========================================================
WHAT HAPPENS INTERNALLY
=========================================================

transfer():

1. deducts ETH from sender contract
2. sends ETH externally
3. triggers receiver execution
4. reverts if receiver fails

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Expand VALUE field in Remix

---------------------------------------------------------

STEP 3:
Enter:
1 ether

---------------------------------------------------------

STEP 4:
Call:
deposit()

---------------------------------------------------------

STEP 5:
Call:
contractBalance()

EXPECTED:
1000000000000000000

(1 ETH in wei)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 7:
Call:
withdraw(500000000000000000)

(0.5 ETH)

---------------------------------------------------------

STEP 8:
Call:
balances(your_address)

EXPECTED:
0.5 ETH remaining

=========================================================
IMPORTANT PAYABLE UNDERSTANDING
=========================================================

Functions receiving ETH
must be marked:

payable

---------------------------------------------------------

Otherwise:
transaction reverts.

=========================================================
WEI UNDERSTANDING
=========================================================

1 ETH =
1,000,000,000,000,000,000 wei

---------------------------------------------------------

Solidity stores ETH in:
wei internally.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External ETH transfer dangerous
if state updated too late.

---------------------------------------------------------
2. DOS VIA transfer()
---------------------------------------------------------

2300 gas may break receivers.

---------------------------------------------------------
3. LOCKED ETH
---------------------------------------------------------

No withdraw path exists.

---------------------------------------------------------
4. FAILED TRANSFER ASSUMPTIONS
---------------------------------------------------------

Receiver may revert intentionally.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

External ETH transfer =
external interaction.

---------------------------------------------------------

Treat as:
UNTRUSTED execution.

=========================================================
CEI PATTERN
=========================================================

SAFE ORDER:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Used in withdraw() above.

=========================================================
WHY transfer() BECAME LESS PREFERRED
=========================================================

Modern Solidity often prefers:

call{value: amount}()

---------------------------------------------------------

Reason:
2300 gas assumptions became unreliable.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is ETH transfer ordered safely?
- Can receiver reenter?
- Can transfer fail unexpectedly?
- Is ETH permanently lockable?
- Are balances updated before transfer?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

State updated AFTER transfer.

---------------------------------------------------------

Attacker contract:
reenters withdraw repeatedly.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. ETH movement
2. State-update ordering
3. External interaction timing
4. Revert behavior
5. Receiver execution flow

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add vulnerable withdraw()
2. Move transfer BEFORE balance update
3. Analyze reentrancy risk
4. Fix using CEI pattern

BONUS:
Implement withdraw using:
call{value: amount}()

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- transfer() sends native ETH
- payable functions receive ETH
- msg.value contains sent ETH
- transfer() forwards 2300 gas
- External ETH transfers are dangerous
- CEI pattern improves security
- State must update before transfer
- ETH stored internally as wei
- Auditors trace ETH movement carefully
- Interactions create reentrancy risk

=========================================================
*/
/*
Audit Report

Title: Reentrancy Vulnerability in withdraw()

Severity: High because an attacker can repeatedly withdraw
ETH before their balance is updated, potentially draining
the entire contract balance.

Location:
Contract: EthTransferMechanicsVul
Function: withdraw()

Vulnerability Description:

The withdraw() function performs an external ETH transfer
before updating the user's balance.

When ETH is sent using:

    call{value: _amount}()

control is transferred to the recipient contract.

A malicious contract can use its receive() or fallback()
function to re-enter withdraw() before the balance is
reduced.

Since the balance update occurs after the external call,
the balance check continues to pass during each reentrant
call, allowing multiple withdrawals from a single deposit.

Impact:

An attacker can drain all ETH held by the contract.

Potential consequences include:

- theft of user funds
- complete contract balance drain
- protocol insolvency
- denial of service to legitimate users

Proof of Concept:

1. Deploy EthTransferMechanicsVul

2. Deposit ETH from multiple users

3. Deploy ReentrancyAttacker pointing to the vulnerable
   contract

4. Call:

       attack()

   with 1 ETH

5. The attacker deposits 1 ETH and immediately calls:

       withdraw(1 ether)

6. Vulnerable contract sends ETH before updating balance

7. Attacker's receive() function executes and calls:

       withdraw(1 ether)

   again

8. Since balance has not yet been reduced, the balance
   check still passes

9. Process repeats until the vulnerable contract's ETH
   balance is drained

Root Cause:

The contract violates the
Checks-Effects-Interactions (CEI) pattern.

State changes occur after the external interaction.

Vulnerable code:

    (bool success,) =
        payable(msg.sender).call{value: _amount}("");

    require(success, "Transfer failed");

    balances[msg.sender] -= _amount;

Recommendation:

Follow the Checks-Effects-Interactions pattern by updating
state before performing external calls.

Example:

    balances[msg.sender] -= _amount;

    (bool success,) =
        payable(msg.sender).call{value: _amount}("");

    require(success, "Transfer failed");

Additionally, use OpenZeppelin's ReentrancyGuard for
defense-in-depth protection.

Example:

    function withdraw(
        uint256 amount
    )
        external
        nonReentrant
    {
        ...
    }

Status:

Fixed in patched implementation.

*/

// Patched code
contract EthTransferMechanics {

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "No ETH sent"
        );

        balances[msg.sender] += msg.value;
    }

    /*
        PATCHED:
        Checks -> Effects -> Interactions
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

        /*
            EFFECTS FIRST
        */
        balances[msg.sender] -= _amount;

        /*
            INTERACTION LAST
        */
        (bool success, ) =
            payable(msg.sender).call{value: _amount}("");

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