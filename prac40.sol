// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Add nested if conditions
CONCEPT: Branching logic
=========================================================

OBJECTIVE

- Learn nested if-condition execution
- Understand branching logic in Solidity
- Learn multi-level decision flow
- Understand auditor-style path tracing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested if statements create:
multiple execution branches.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Different inputs cause:
different execution paths.

Auditors must trace:
EVERY possible branch.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Many vulnerabilities hide inside:
rare execution branches.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested branching appears in:

- access control
- DeFi fee systems
- staking rewards
- liquidation logic
- governance rules
- NFT minting limits

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- unreachable branches
- incorrect conditions
- missing else logic
- privilege escalation
- inconsistent state updates

=========================================================
*/

contract NestedIfConditions {

    /*
        OWNER ADDRESS
    */
    address public owner;

    /*
        USER SCORES
    */
    mapping(address => uint256) public scores;

    /*
        USER LEVELS
    */
    mapping(address => string) public levels;

    /*
        CONSTRUCTOR
    */
    constructor() {

        owner = msg.sender;
    }

    /*
    =====================================================
    NESTED IF LOGIC
    =====================================================
    */

    function evaluateUser(
        uint256 _score,
        bool _premium
    )
        external
    {

        /*
            FIRST BRANCH

            Check minimum score.
        */
        if (_score >= 50) {

            /*
                SECOND BRANCH

                Check premium status.
            */
            if (_premium == true) {

                /*
                    THIRD BRANCH

                    Check elite score.
                */
                if (_score >= 90) {

                    levels[msg.sender] =
                        "Elite Premium";

                } else {

                    levels[msg.sender] =
                        "Premium";
                }

            } else {

                /*
                    NON-PREMIUM USER
                */
                levels[msg.sender] =
                    "Standard";
            }

            /*
                SAVE SCORE
            */
            scores[msg.sender] = _score;

        } else {

            /*
                LOW SCORE BRANCH
            */
            levels[msg.sender] =
                "Rejected";
        }
    }

    /*
    =====================================================
    OWNER BONUS FUNCTION
    =====================================================
    */

    function ownerBonus(
        address _user
    )
        external
    {

        /*
            FIRST CONDITION:
            owner check
        */
        if (msg.sender == owner) {

            /*
                SECOND CONDITION:
                user must exist
            */
            if (scores[_user] > 0) {

                /*
                    THIRD CONDITION:
                    high score required
                */
                if (scores[_user] >= 80) {

                    scores[_user] += 20;
                }
            }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
evaluateUser(95, true)

=========================================================

STEP 1:
if (_score >= 50)

CHECK:
95 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
if (_premium == true)

CHECK:
true == true

RESULT:
true

---------------------------------------------------------

STEP 3:
if (_score >= 90)

CHECK:
95 >= 90

RESULT:
true

---------------------------------------------------------

EXECUTION PATH:

Elite Premium branch

---------------------------------------------------------

FINAL STORAGE:

levels[user] = "Elite Premium"

scores[user] = 95

=========================================================
ANOTHER TRACE
=========================================================

CALL:
evaluateUser(60, false)

---------------------------------------------------------

STEP 1:
60 >= 50

RESULT:
true

---------------------------------------------------------

STEP 2:
premium == true

RESULT:
false

---------------------------------------------------------

EXECUTION PATH:

Standard branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Standard"

=========================================================
LOW SCORE TRACE
=========================================================

CALL:
evaluateUser(20, true)

---------------------------------------------------------

STEP 1:
20 >= 50

RESULT:
false

---------------------------------------------------------

EXECUTION JUMPS TO:

else branch

---------------------------------------------------------

FINAL STATE:

levels[user] = "Rejected"

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
evaluateUser(95, true)

---------------------------------------------------------

STEP 3:
Call:
levels(your_address)

EXPECTED:
"Elite Premium"

---------------------------------------------------------

STEP 4:
Call:
evaluateUser(60, false)

EXPECTED:
"Standard"

---------------------------------------------------------

STEP 5:
Call:
evaluateUser(20, true)

EXPECTED:
"Rejected"

---------------------------------------------------------

STEP 6:
Call:
ownerBonus(your_address)

FROM:
owner account

---------------------------------------------------------

STEP 7:
Call:
scores(your_address)

OBSERVE:
Bonus added if conditions met

=========================================================
IMPORTANT BRANCHING UNDERSTANDING
=========================================================

Nested if statements create:
multiple execution paths.

---------------------------------------------------------

Every branch may:
- modify state differently
- skip logic
- create vulnerabilities

=========================================================
EXECUTION TREE
=========================================================

Example:

IF score >= 50
    |
    +-- premium?
          |
          +-- elite?
          |
          +-- standard

---------------------------------------------------------

Auditors mentally trace:
ALL branches.

=========================================================
WHY NESTED LOGIC IS DANGEROUS
=========================================================

Complex branching may cause:

- forgotten edge cases
- inconsistent updates
- bypass conditions
- privilege escalation

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING ELSE BRANCH
---------------------------------------------------------

State may remain unchanged unexpectedly.

---------------------------------------------------------
2. UNREACHABLE CODE
---------------------------------------------------------

Incorrect condition order
may block execution paths.

---------------------------------------------------------
3. INCONSISTENT STATE
---------------------------------------------------------

Different branches may:
update state differently.

---------------------------------------------------------
4. PRIVILEGE ESCALATION
---------------------------------------------------------

Incorrect nested checks
may bypass authorization.

=========================================================
GAS OBSERVATION
=========================================================

More branching:
More execution complexity.

---------------------------------------------------------

Deeper nesting:
Harder auditing.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can attacker reach hidden branch?
- Are all paths validated?
- Does every path maintain invariants?
- Are branches mutually exclusive?
- Is state updated consistently?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer forgets else branch.

Attacker triggers unexpected path.

Result:
stale or corrupted state.

---------------------------------------------------------

ANOTHER RISK

Incorrect nested access-control logic
may allow unauthorized execution.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Every condition
2. Every branch
3. Every state update
4. Every revert path
5. Every skipped operation

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add blacklist logic
2. Add VIP user branch
3. Add paused-contract branch

Then manually trace:
ALL execution paths.

BONUS:
Convert nested ifs into:
require() + early returns.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested if creates multiple execution paths
- Branching changes execution flow
- Auditors must trace every branch
- Missing branches create vulnerabilities
- Complex logic increases audit difficulty
- State updates differ across branches
- Incorrect nesting may bypass checks
- Edge cases matter heavily
- Branch analysis is critical in auditing
- Execution tracing is essential for security reviews

=========================================================
*/
/*
Audit Report

Title: Silent Failure in ownerBonus() Access Control

Severity: Low

Location:
Contract: NestedIfConditions
Function: ownerBonus()

Vulnerability Description:

The ownerBonus() function uses nested if-statements for access control
instead of explicit validation using require().

    if (msg.sender == owner) {
        ...
    }

When a non-owner calls the function, execution silently exits without
reverting.

This behavior may mislead users, integrators, or frontend applications
into believing the operation succeeded when no action was performed.

Impact:

- Lack of explicit authorization enforcement
- Poor user experience
- Difficult integration debugging
- Reduced auditability and code clarity

No unauthorized state modification is possible because the bonus logic
remains protected by the owner check.

Proof of Concept:

1. Deploy contract

2. User calls:
   evaluateUser(90, true)

3. Switch to a non-owner account

4. Call:
   ownerBonus(user)

5. Transaction succeeds

6. Check:
   scores(user)

7. Score remains unchanged

Observe:
The transaction does not revert even though the caller is not authorized.

Root Cause:

Authorization is implemented using nested if-statements rather than
explicit require() validation.

The function silently skips execution instead of rejecting unauthorized
calls.

Recommendation:

Replace the access-control condition with an explicit require() check.

Example:

    function ownerBonus(address _user) external {
        require(
            msg.sender == owner,
            "Not owner"
        );

        require(
            scores[_user] > 0,
            "No score"
        );

        require(
            scores[_user] >= 80,
            "Score too low"
        );

        scores[_user] += 20;
    }

This provides clear authorization enforcement and improves
auditability.
*/