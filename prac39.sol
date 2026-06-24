// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use multiple require checks
CONCEPT: Execution guards
=========================================================

OBJECTIVE

- Learn how multiple require() checks work
- Understand execution guards in Solidity
- Learn defensive validation patterns
- Understand fail-fast security design

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

require() acts as an execution guard.

If ANY require() fails:
- execution stops
- transaction reverts
- state changes rollback

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Multiple require() checks create:
layered protection.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Smart contracts must validate:
- caller
- values
- balances
- permissions
- timing
- protocol rules

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Multiple require() checks used in:

- ERC20 transfers
- staking contracts
- governance systems
- lending protocols
- NFT minting
- DEX routers

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- missing validations
- incorrect validation order
- bypass possibilities
- access control flaws
- logic assumptions

=========================================================
*/
contract MultipleRequireChecksVul {

    mapping(address => uint256) public balances;

    bool public paused;

    mapping(address => bool) public blacklisted;

    function withdraw(
        uint256 _amount
    )
        external
    {
        // Missing pause check
        // Missing blacklist check

        balances[msg.sender] -= _amount;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(10)

=========================================================

STEP 1:
require(10 > 0)

RESULT:
true

---------------------------------------------------------

STEP 2:
require(10 <= MAX_DEPOSIT)

RESULT:
true

---------------------------------------------------------

STEP 3:
Balance limit check

RESULT:
true

---------------------------------------------------------

ALL CHECKS PASSED

---------------------------------------------------------

STORAGE UPDATE:

balances[msg.sender] += 10

=========================================================
FAILURE TRACE
=========================================================

CALL:
deposit(0)

---------------------------------------------------------

STEP 1:
require(0 > 0)

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS IMMEDIATELY

---------------------------------------------------------

IMPORTANT:
Other require() checks never execute.

=========================================================
ANOTHER FAILURE TRACE
=========================================================

CALL:
resetBalance(user)

BY:
non-owner

---------------------------------------------------------

STEP 1:
require(msg.sender == owner)

RESULT:
false

---------------------------------------------------------

EXECUTION STOPS IMMEDIATELY

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(10)

EXPECTED:
Success

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
deposit(0)

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
deposit(500 ether)

EXPECTED:
Revert

---------------------------------------------------------

STEP 6:
Switch account in Remix

---------------------------------------------------------

STEP 7:
Call:
resetBalance(your_address)

EXPECTED:
Revert (not owner)

=========================================================
IMPORTANT REQUIRE UNDERSTANDING
=========================================================

require() acts as:
EXECUTION GUARD.

---------------------------------------------------------

If condition fails:
- execution stops
- revert triggered
- state rolled back

=========================================================
FAIL-FAST PRINCIPLE
=========================================================

Solidity follows:
FAIL FAST design.

---------------------------------------------------------

Bad input:
Stop immediately.

=========================================================
ORDER OF REQUIRE CHECKS
=========================================================

BEST PRACTICE:

1. Cheapest checks first
2. Expensive checks later

---------------------------------------------------------

Reason:
Save gas on early failure.

=========================================================
GOOD VALIDATION ORDER
=========================================================

GOOD:

1. msg.sender checks
2. zero-address checks
3. value checks
4. expensive loops/calls

=========================================================
BAD VALIDATION ORDER
=========================================================

BAD:

1. expensive computation
2. external calls
3. validation later

---------------------------------------------------------

Problem:
Wasted gas and risk.

=========================================================
GAS OBSERVATION
=========================================================

FAILED REQUIRE:
Still consumes gas.

---------------------------------------------------------

Earlier failure:
Usually cheaper.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MISSING REQUIRE CHECKS
---------------------------------------------------------

Very common vulnerability source.

---------------------------------------------------------
2. INCORRECT ACCESS CONTROL
---------------------------------------------------------

Missing owner checks
can destroy protocols.

---------------------------------------------------------
3. VALIDATION ORDER
---------------------------------------------------------

Cheap checks should happen first.

---------------------------------------------------------
4. DEFENSE IN DEPTH
---------------------------------------------------------

Multiple require() checks
create layered security.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Missing require() allows:
- unauthorized access
- invalid balances
- protocol corruption

---------------------------------------------------------

ANOTHER RISK

Incorrect ordering may:
waste gas or expose reentrancy.

=========================================================
REAL AUDITOR QUESTIONS
=========================================================

Auditors ask:

- What assumptions exist?
- Are all assumptions validated?
- Can attacker bypass checks?
- Is access control enforced?
- Are limits bounded safely?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add withdraw() function
2. Add:
   - pause check
   - balance check
   - owner blacklist check

BONUS:
Replace require strings
with custom errors.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- require() creates execution guards
- Failed require() reverts transaction
- Multiple require() checks add layered protection
- Validation order matters
- Cheap checks should execute first
- Fail-fast principle improves safety
- Missing checks create vulnerabilities
- Access control is critical
- Auditors inspect validation carefully
- Defense-in-depth improves smart contract security

=========================================================
*/
/*
Audit Report

Title: Missing Pause and Blacklist Validation in withdraw()

Severity: Medium because unauthorized or restricted users
can continue interacting with the protocol despite
security controls being enabled.

Location:
Contract: MultipleRequireChecks
Function: withdraw() (Mini Challenge Implementation)

Vulnerability Description:

The withdraw() function fails to implement all required
execution guards before processing withdrawals.

Specifically, the function does not verify:

- whether the protocol is paused
- whether the caller is blacklisted

As a result, users may continue withdrawing funds even
when emergency shutdown mechanisms or blacklist controls
have been activated.

This weakens protocol security and bypasses intended
administrative protections.

Impact:

An attacker or restricted user may:

- bypass emergency pause controls
- bypass blacklist restrictions
- continue withdrawing funds during incidents
- violate protocol security policies

This can undermine administrative responses to attacks,
exploits, or operational emergencies.

Proof of Concept:

1. Deploy contract

2. User deposits funds

3. Owner activates emergency pause:

   paused = true

4. User calls:

   withdraw(10)

5. Withdrawal succeeds despite protocol being paused

--------------------------------------------------

OR

--------------------------------------------------

1. Owner blacklists attacker:

   blacklisted[attacker] = true

2. Attacker calls:

   withdraw(10)

3. Withdrawal succeeds despite blacklist status

Root Cause:

The withdraw() function only validates user balances.

Critical execution guards are missing:

- pause validation
- blacklist validation

The function does not enforce all protocol assumptions
before updating state.

Recommendation:

Add layered validation checks before executing
withdrawal logic.

Example:

if (paused) {
    revert ContractPaused();
}

if (blacklisted[msg.sender]) {
    revert BlacklistedUser();
}

if (balances[msg.sender] < amount) {
    revert InsufficientBalance();
}

balances[msg.sender] -= amount;

Additionally, follow the
Checks -> Effects -> Interactions (CEI) pattern
for all state-changing functions.

This ensures that protocol restrictions are enforced
before any state modifications occur
*/

//Patched code
contract MultipleRequireChecksPatched {

    error ContractPaused();
    error BlacklistedUser();
    error InsufficientBalance();

    mapping(address => uint256) public balances;

    mapping(address => bool) public blacklisted;

    bool public paused;

    function withdraw(
        uint256 _amount
    )
        external
    {
        // CHECK #1
        if (paused) {
            revert ContractPaused();
        }

        // CHECK #2
        if (blacklisted[msg.sender]) {
            revert BlacklistedUser();
        }

        // CHECK #3
        if (
            balances[msg.sender] < _amount
        ) {
            revert InsufficientBalance();
        }

        balances[msg.sender] -= _amount;
    }
}