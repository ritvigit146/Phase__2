// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use modifier before function
CONCEPT: Pre-execution flow
=========================================================

OBJECTIVE

- Learn how modifiers work
- Understand pre-execution flow
- Learn execution wrapping behavior
- Understand access-control architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Modifiers execute:
BEFORE function body.

They act like:
execution guards/wrappers.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Modifiers can:
- validate conditions
- block execution
- run code before function
- run code after function

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most production contracts use modifiers for:

- access control
- pause logic
- validation
- reentrancy protection
- execution restrictions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Modifiers used in:

- Ownable contracts
- Pausable contracts
- ReentrancyGuard
- DeFi protocols
- governance systems
- staking platforms

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- modifier execution order
- missing modifiers
- bypass possibilities
- modifier side effects
- access-control flaws

=========================================================
*/

contract ModifierExecutionFlow {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        PAUSE STATUS
    */
    bool public paused;

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        CONSTRUCTOR

        Runs once during deployment.
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    MODIFIER: ONLY OWNER
    =====================================================
    */

    modifier onlyOwner() {

        /*
            PRE-EXECUTION CHECK

            Runs BEFORE function body.
        */
        require(
            msg.sender == owner,
            "Not owner"
        );

        /*
            SPECIAL SYMBOL: _;

            Represents:
            function body execution point.
        */
        _;
    }

    /*
    =====================================================
    MODIFIER: WHEN NOT PAUSED
    =====================================================
    */

    modifier whenNotPaused() {

        /*
            PRE-EXECUTION VALIDATION
        */
        require(
            paused == false,
            "Contract paused"
        );

        /*
            Continue to function body.
        */
        _;
    }

    /*
    =====================================================
    OWNER-ONLY FUNCTION
    =====================================================
    */

    function setPaused(
        bool _status
    )
        external
        onlyOwner
    {

        /*
            Function body executes ONLY
            after modifier passes.
        */
        paused = _status;
    }

    /*
    =====================================================
    DEPOSIT FUNCTION
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
        whenNotPaused
    {

        /*
            Function body executes ONLY
            if modifier allows execution.
        */
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    MULTIPLE MODIFIERS
    =====================================================
    */

    function emergencyReset(
        address _user
    )
        external
        onlyOwner
        whenNotPaused
    {

        /*
            Executes ONLY if:
            - caller is owner
            - contract not paused
        */
        balances[_user] = 0;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(50)

=========================================================

STEP 1:
Modifier executes FIRST:

whenNotPaused

---------------------------------------------------------

CHECK:
paused == false

RESULT:
true

---------------------------------------------------------

STEP 2:
_; reached inside modifier.

Execution enters function body.

---------------------------------------------------------

STEP 3:
Function body executes.

require(_amount > 0)

---------------------------------------------------------

STEP 4:
Storage updated.

balances[Alice] += 50

=========================================================
FAILED MODIFIER TRACE
=========================================================

SET:
paused = true

---------------------------------------------------------

CALL:
deposit(50)

---------------------------------------------------------

STEP 1:
Modifier executes FIRST.

CHECK:
paused == false

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

FUNCTION BODY NEVER EXECUTES

=========================================================
OWNER MODIFIER TRACE
=========================================================

CALL:
setPaused(true)

FROM:
non-owner account

---------------------------------------------------------

STEP 1:
onlyOwner modifier executes.

CHECK:
msg.sender == owner

RESULT:
false

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

Function body skipped completely.

=========================================================
MULTIPLE MODIFIER FLOW
=========================================================

CALL:
emergencyReset(user)

=========================================================

EXECUTION ORDER:

1. onlyOwner modifier
2. whenNotPaused modifier
3. function body

---------------------------------------------------------

If ANY modifier fails:
execution stops immediately.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(50)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
50

---------------------------------------------------------

STEP 4:
Call:
setPaused(true)

FROM:
owner account

---------------------------------------------------------

STEP 5:
Call:
deposit(10)

EXPECTED:
Revert

---------------------------------------------------------

STEP 6:
Switch Remix account

---------------------------------------------------------

STEP 7:
Call:
setPaused(false)

FROM:
non-owner account

EXPECTED:
Revert

=========================================================
IMPORTANT MODIFIER UNDERSTANDING
=========================================================

Modifier code executes:
AROUND function body.

---------------------------------------------------------

BEFORE _; :
pre-execution logic

---------------------------------------------------------

AFTER _; :
post-execution logic

=========================================================
VERY IMPORTANT SYMBOL
=========================================================

_;

means:

"Insert function body here"

=========================================================
MODIFIER EXECUTION MODEL
=========================================================

modifier check()
{
    require(...);

    _;

    additional logic
}

---------------------------------------------------------

FLOW:

1. require()
2. function body
3. additional logic

=========================================================
COMMON MODIFIER USE CASES
=========================================================

- onlyOwner
- whenNotPaused
- nonReentrant
- onlyAdmin
- onlyValidator

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING MODIFIER
---------------------------------------------------------

Critical function lacks protection.

---------------------------------------------------------
2. INCORRECT MODIFIER ORDER
---------------------------------------------------------

Execution order may matter.

---------------------------------------------------------
3. SIDE EFFECTS INSIDE MODIFIER
---------------------------------------------------------

Modifiers may unexpectedly:
modify storage.

---------------------------------------------------------
4. ACCESS CONTROL BUGS
---------------------------------------------------------

Improper owner checks
can expose protocol.

=========================================================
GAS OBSERVATION
=========================================================

More modifiers:
More execution cost.

---------------------------------------------------------

Complex modifiers:
increase audit complexity.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which functions use modifiers?
- Which functions forgot modifiers?
- What executes before _; ?
- Can modifiers be bypassed?
- Do modifiers mutate state?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets:
onlyOwner modifier.

Attacker gains admin access.

---------------------------------------------------------

ANOTHER RISK

Modifier updates storage unexpectedly.

Result:
hidden side effects.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Modifier execution order
2. Pre-execution checks
3. Function body flow
4. Post-execution logic
5. Access-control coverage

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist modifier
2. Add transaction-limit modifier
3. Add post-execution event emission

BONUS:
Create custom modifier:
that charges execution fee.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Modifiers execute before function body
- _; represents function execution point
- Modifiers act as execution guards
- Modifiers commonly enforce access control
- Multiple modifiers execute sequentially
- Failed modifier stops execution
- Modifiers can contain pre/post logic
- Missing modifiers create vulnerabilities
- Auditors inspect modifier coverage carefully
- Modifier execution flow is critical for security

=========================================================
*/
/*
Audit Report

Title: Emergency Reset Cannot Execute While Contract Is Paused

Severity: Informational because administrative recovery actions are
blocked during pause state.

Location:
Contract: ModifierExecutionFlow
Function: emergencyReset()

Vulnerability Description:

The emergencyReset() function is protected by both:

                onlyOwner
                whenNotPaused

Execution requires:

                msg.sender == owner

and

                paused == false

As a result, the owner cannot execute emergencyReset()
while the contract is paused.

In many protocols, emergency or recovery functions are
expected to remain available during paused states so that
administrators can perform corrective actions.

Impact:

No direct security impact exists.

However:

- administrative recovery actions are blocked
- incident response flexibility is reduced
- operational maintenance becomes harder

Proof of Concept:

                1. Deploy contract

                2. Owner calls:
                    setPaused(true)

                3. Owner calls:
                    emergencyReset(user)

                4. whenNotPaused modifier fails

                5. Transaction reverts

                6. User balance cannot be reset

Root Cause:

The emergencyReset() function uses the
whenNotPaused modifier.

This prevents execution during pause state,
even for authorized administrators.

Recommendation:

Consider whether emergency actions should remain
available while the contract is paused.

Example:

                function emergencyReset(address _user)
                    external
                    onlyOwner
                {
                    balances[_user] = 0;
                }

If the intended design is to allow administrative
recovery during emergencies, remove the
whenNotPaused modifier.

*/