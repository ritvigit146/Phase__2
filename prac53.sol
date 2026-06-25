// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Send ETH using call
CONCEPT: Low-level call behavior
=========================================================

OBJECTIVE

- Learn how call() sends ETH
- Understand low-level external calls
- Learn return-value handling
- Understand dangerous execution behavior

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

call() is the most flexible
and dangerous external interaction method.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

call():

- can send ETH
- can call functions
- forwards remaining gas
- returns success/failure manually

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern Solidity commonly uses:
call{value: amount}()

instead of transfer().

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

call() used in:

- DeFi protocols
- vaults
- proxies
- multicall systems
- upgradeable contracts
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- reentrancy windows
- unchecked return values
- external-call ordering
- arbitrary call risks
- gas forwarding behavior

=========================================================
*/
contract LowLevelCallExampleVul {

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        balances[msg.sender] += msg.value;
    }

    /*
        VULNERABLE
        Reentrancy possible.
    */
    function vulnerableWithdraw(
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
        */
        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        require(
            success,
            "Transfer failed"
        );

        /*
            EFFECTS LAST

            Too late.
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
msg.value = 1 ETH

---------------------------------------------------------

STEP 2:
balances[Alice] += 1 ETH

---------------------------------------------------------

STEP 3:
Contract receives ETH.

=========================================================
SAFE WITHDRAW TRACE
=========================================================

CALL:
safeWithdraw(1 ETH)

=========================================================

STEP 1:
Balance validated.

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
Low-level external call executes.

call{value: 1 ETH}("")

---------------------------------------------------------

ETH transferred externally.

---------------------------------------------------------
STEP 4:
success returned.

success = true

---------------------------------------------------------
STEP 5:
require(success)

RESULT:
true

---------------------------------------------------------

TRANSACTION SUCCEEDS

=========================================================
VERY IMPORTANT call() UNDERSTANDING
=========================================================

call():

- forwards remaining gas
- allows arbitrary execution
- returns success manually

---------------------------------------------------------

Unlike transfer():

call() does NOT auto-revert.

=========================================================
RETURN VALUES
=========================================================

call() returns:

(bool success, bytes memory data)

---------------------------------------------------------

success:
true/false

---------------------------------------------------------

data:
returned function data

=========================================================
WHY call() IS DANGEROUS
=========================================================

Receiving contract gets:
almost ALL remaining gas.

---------------------------------------------------------

Meaning:
receiver can execute complex logic.

---------------------------------------------------------

Including:
reentrant attacks.

=========================================================
VULNERABLE TRACE
=========================================================

CALL:
vulnerableWithdraw(1 ETH)

=========================================================

STEP 1:
Validation passes.

---------------------------------------------------------

STEP 2:
External call executes FIRST.

---------------------------------------------------------

Attacker contract receives ETH.

---------------------------------------------------------

fallback()/receive() executes.

---------------------------------------------------------

Attacker reenters:
vulnerableWithdraw()

---------------------------------------------------------

IMPORTANT:
balance NOT reduced yet.

---------------------------------------------------------

Multiple withdrawals possible.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 3:
Call:
deposit()

---------------------------------------------------------

STEP 4:
Call:
contractBalance()

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 5:
Call:
safeWithdraw(0.5 ether)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
0.5 ETH remaining

=========================================================
IMPORTANT DIFFERENCE
=========================================================

---------------------------------------------------------
transfer()
---------------------------------------------------------

- 2300 gas
- auto-reverts
- limited execution

---------------------------------------------------------
call()
---------------------------------------------------------

- forwards gas
- manual success handling
- highly flexible
- more dangerous

=========================================================
MODERN SOLIDITY PREFERENCE
=========================================================

Modern Solidity often prefers:

call{value: amount}()

---------------------------------------------------------

Reason:
transfer() gas assumptions outdated.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

Largest risk with call().

---------------------------------------------------------
2. UNCHECKED SUCCESS
---------------------------------------------------------

ETH transfer may silently fail.

---------------------------------------------------------
3. ARBITRARY EXECUTION
---------------------------------------------------------

Receiver contract may behave maliciously.

---------------------------------------------------------
4. DOS RISKS
---------------------------------------------------------

Receiver intentionally reverts.

=========================================================
IMPORTANT SECURITY CONCEPT
=========================================================

Every external call =
UNTRUSTED EXECUTION

---------------------------------------------------------

Never trust:
receiver behavior.

=========================================================
CEI PATTERN
=========================================================

SAFE ORDER:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

safeWithdraw() follows this.

=========================================================
GAS OBSERVATION
=========================================================

call():
forwards remaining gas by default.

---------------------------------------------------------

Makes execution more flexible,
but more dangerous.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Is call() ordered safely?
- Can receiver reenter?
- Is success checked?
- Can ETH become stuck?
- Is arbitrary execution possible?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malicious receiver contract:

1. receives ETH
2. fallback() triggers
3. reenters vulnerable function
4. drains contract repeatedly

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External interaction timing
2. State-update ordering
3. Gas forwarding behavior
4. Reentrancy windows
5. Failure handling

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add nonReentrant modifier
2. Protect vulnerableWithdraw()
3. Add event emission
4. Handle failed transfers safely

BONUS:
Create attacker contract
to simulate reentrancy.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- call() sends ETH using low-level interaction
- call() forwards remaining gas
- call() requires manual success checking
- call() enables arbitrary external execution
- Reentrancy risk increases heavily with call()
- CEI pattern improves safety
- External calls are untrusted interactions
- State updates must occur before call()
- Auditors inspect call() extremely carefully
- Low-level calls are core to DeFi architecture

=========================================================
*/
/*
Audit Report

Title: Reentrancy Vulnerability in vulnerableWithdraw()

Severity: High because an attacker can repeatedly withdraw
ETH before their balance is updated, potentially draining
all ETH held by the contract.

Location:
Contract: LowLevelCallExample
Function: vulnerableWithdraw()

Vulnerability Description:

The vulnerableWithdraw() function performs an external
ETH transfer using low-level call() before updating the
user's balance.

Since call() forwards almost all remaining gas to the
recipient, a malicious contract can execute arbitrary code
within its receive() or fallback() function.

An attacker can re-enter vulnerableWithdraw() before the
balance reduction occurs, allowing multiple withdrawals
using the same deposited balance.

Impact:

An attacker can drain all ETH stored in the contract.

Potential consequences include:

- theft of user funds
- complete contract balance drain
- protocol insolvency
- denial of service to legitimate users

Proof of Concept:

1. Deploy LowLevelCallExample

2. Deposit ETH into the contract

3. Deploy a malicious attacker contract with a receive()
   function that calls:

       vulnerableWithdraw()

4. Attacker deposits 1 ETH

5. Attacker calls:

       vulnerableWithdraw(1 ether)

6. Contract executes:

       call{value: 1 ether}()

7. Attacker's receive() function executes

8. Attacker re-enters:

       vulnerableWithdraw(1 ether)

9. Balance check still passes because storage has not yet
   been updated

10. Process repeats until contract ETH balance is drained

Root Cause:

The function violates the
Checks-Effects-Interactions (CEI) pattern.

External interaction occurs before state modification.

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

Update user balances before performing external calls.

Follow the CEI pattern:

    balances[msg.sender] -= _amount;

    (bool success, ) =
        payable(msg.sender).call{
            value: _amount
        }("");

    require(
        success,
        "Transfer failed"
    );

Additionally, consider using OpenZeppelin's
ReentrancyGuard as an additional defense layer.

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
contract LowLevelCallExamplePatched {

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        balances[msg.sender] += msg.value;
    }

    /*
        PATCHED
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