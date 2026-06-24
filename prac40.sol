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
contract NestedIfConditionsVul {

    address public owner;

    mapping(address => uint256) public scores;

    mapping(address => string) public levels;

    mapping(address => bool) public vipUsers;

    mapping(address => bool) public blacklisted;

    bool public paused;

    constructor() {
        owner = msg.sender;
    }

    function ownerBonus(
        address _user
    )
        external
    {
        /*
            VULNERABILITY:

            Missing owner validation.
        */

        if (scores[_user] > 0) {

            if (scores[_user] >= 80) {

                scores[_user] += 20;
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

Title: Missing Access Control in ownerBonus()

Severity: Medium because unauthorized users can
modify protocol state by granting score bonuses.

Location:
Contract: NestedIfConditions
Function: ownerBonus()

Vulnerability Description:

The ownerBonus() function performs privileged score
modifications but does not properly restrict access
to authorized users.

The function relies only on nested score checks and
does not verify that the caller is the contract owner.

As a result, any external user can execute the bonus
logic and alter user scores.

Impact:

An attacker can:

- modify user scores
- grant unauthorized bonuses
- manipulate level calculations
- corrupt protocol state

If scores influence rewards, governance rights,
staking benefits, or user privileges, the impact
could become significant.

Proof of Concept:

1. Deploy contract

2. User Alice obtains score:

   scores[Alice] = 85

3. Attacker calls:

   ownerBonus(Alice)

4. Nested conditions pass:

   scores[Alice] > 0
   scores[Alice] >= 80

5. Contract executes:

   scores[Alice] += 20

6. Final score:

   105

Root Cause:

The function contains nested business-logic checks
but lacks authorization validation.

No owner verification exists before executing
privileged state updates.

Recommendation:

Add explicit access control before executing bonus
logic.

Example:

require(
    msg.sender == owner,
    "Not owner"
);

Additionally consider:

- pause protection
- blacklist validation
- custom errors

Follow the pattern:

Checks -> Effects -> Interactions

to ensure all execution paths remain secure
*/

//Patched code
contract NestedIfConditions {

    error NotOwner();
    error ContractPaused();
    error BlacklistedUser();

    address public owner;

    mapping(address => uint256) public scores;

    mapping(address => string) public levels;

    mapping(address => bool) public vipUsers;

    mapping(address => bool) public blacklisted;

    bool public paused;

    constructor() {
        owner = msg.sender;
    }

    function ownerBonus(
        address _user
    )
        external
    {
        /*
            CHECK #1
        */
        if (paused) {
            revert ContractPaused();
        }

        /*
            CHECK #2
        */
        if (msg.sender != owner) {
            revert NotOwner();
        }

        /*
            CHECK #3
        */
        if (blacklisted[_user]) {
            revert BlacklistedUser();
        }

        /*
            EFFECTS
        */
        if (scores[_user] >= 80) {

            scores[_user] += 20;
        }
    }
}