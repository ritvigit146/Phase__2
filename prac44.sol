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
contract ModifierExecutionFlowVul {

    address public owner;

    bool public paused;

    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Not owner"
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            paused == false,
            "Contract paused"
        );
        _;
    }

    function setPaused(
        bool _status
    )
        external
        onlyOwner
    {
        paused = _status;
    }

    function deposit(
        uint256 _amount
    )
        external
        whenNotPaused
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    VULNERABILITY

    Missing onlyOwner modifier.

    ANY USER can reset balances.
    =====================================================
    */

    function emergencyReset(
        address _user
    )
        external
        whenNotPaused
    {
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
Title: Missing Pause Protection on depositWithBonus()

Severity: Medium because users can continue modifying balances even when
the contract is intended to be paused.

Location:
Contract: ModifierExecutionFlow
Function: depositWithBonus() (hypothetical function added without modifier)

Vulnerability Description:

The contract relies on the whenNotPaused modifier to prevent state changes
while the protocol is paused.

If a developer adds a new balance-modifying function but forgets to apply
the whenNotPaused modifier, users can bypass the pause mechanism and
continue interacting with the protocol.

This creates inconsistent security enforcement because some functions
respect the paused state while others do not.

Impact:

An attacker or normal user can continue updating balances while the
protocol is paused.

If pause functionality is intended for:

- emergency response
- incident containment
- protocol upgrades
- vulnerability mitigation

then the protection becomes ineffective.

Proof of Concept:

1. Deploy contract

2. Owner calls:
   setPaused(true)

3. Attacker calls:
   depositWithBonus(100)

4. Transaction succeeds because no
   whenNotPaused modifier exists.

5. balances[attacker] increases despite
   protocol being paused.

Root Cause:

The function lacks the whenNotPaused modifier.

Security assumptions rely on pause protection,
but enforcement is not applied consistently
across all state-changing functions.

Recommendation:

Apply the whenNotPaused modifier to every
function that changes protocol state.

Example:

function depositWithBonus(
    uint256 _amount
)
    external
    whenNotPaused
{
    ...
}

*/

// Patched code
contract ModifierExecutionFlow {

    address public owner;

    bool public paused;

    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Not owner"
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            paused == false,
            "Contract paused"
        );
        _;
    }

    function setPaused(
        bool _status
    )
        external
        onlyOwner
    {
        paused = _status;
    }

    function deposit(
        uint256 _amount
    )
        external
        whenNotPaused
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] += _amount;
    }

    /*
    =====================================================
    PATCH

    onlyOwner added.

    Unauthorized users cannot
    reset balances.
    =====================================================
    */

    function emergencyReset(
        address _user
    )
        external
        onlyOwner
        whenNotPaused
    {
        balances[_user] = 0;
    }
}