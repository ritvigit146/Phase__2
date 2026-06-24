// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Emit events during execution
CONCEPT: Execution tracking
=========================================================

OBJECTIVE

- Learn how Solidity events work
- Understand execution tracking through logs
- Learn event emission flow
- Understand off-chain monitoring architecture

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Events create blockchain logs.

These logs help:
- frontend apps
- indexers
- explorers
- monitoring systems

track contract activity.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Events are NOT contract storage.

They are stored inside:
transaction logs.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Without events:
off-chain systems cannot efficiently
track contract activity.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Events used in:

- ERC20 transfers
- NFT minting
- swaps
- staking
- governance voting
- liquidations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- missing events
- incorrect event ordering
- misleading logs
- sensitive-data leakage
- inconsistent state vs event emission

=========================================================
*/
contract EventExecutionTrackingVul {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    event DepositStarted(
        address indexed user,
        uint256 amount
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits
    );

    function deposit(
        uint256 _amount
    )
        external
    {
        /*
            VULNERABILITY

            Event emitted before validation.

            Off-chain monitoring systems may
            temporarily interpret this as a
            legitimate deposit attempt.
        */
        emit DepositStarted(
            msg.sender,
            _amount
        );

        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );

        balances[msg.sender] += _amount;

        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender]
        );

        totalDeposits += _amount;

        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits
        );
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
emit DepositStarted()

---------------------------------------------------------

LOG CREATED:

user = Alice
amount = 50

---------------------------------------------------------

STEP 2:
Validation checks pass.

---------------------------------------------------------

STEP 3:
Storage updated.

balances[Alice] += 50

---------------------------------------------------------

STEP 4:
emit BalanceUpdated()

---------------------------------------------------------

LOG CREATED:

newBalance = 50

---------------------------------------------------------

STEP 5:
totalDeposits += 50

---------------------------------------------------------

STEP 6:
emit DepositCompleted()

---------------------------------------------------------

LOG CREATED:

amount = 50
totalDeposits = 50

---------------------------------------------------------

TRANSACTION SUCCEEDS

=========================================================
IMPORTANT EVENT UNDERSTANDING
=========================================================

Events are stored in:
transaction logs.

---------------------------------------------------------

NOT inside contract storage.

=========================================================
EVENTS VS STORAGE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

- readable on-chain
- expensive
- persistent state

---------------------------------------------------------
EVENTS
---------------------------------------------------------

- cheaper
- optimized for off-chain reading
- not readable by contracts

=========================================================
IMPORTANT REVERT BEHAVIOR
=========================================================

If transaction reverts:

ALL emitted events disappear.

---------------------------------------------------------

Very important EVM property.

=========================================================
REVERT TRACE
=========================================================

CALL:
validateNumber(50)

=========================================================

STEP 1:
emit ExecutionFailed()

---------------------------------------------------------

Temporary log created.

---------------------------------------------------------

STEP 2:
revert()

---------------------------------------------------------

TRANSACTION REVERTS

---------------------------------------------------------

EVENT LOG ALSO REMOVED

---------------------------------------------------------

FINAL RESULT:

NO event persists on-chain.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Open:
Deployed Contracts panel

---------------------------------------------------------

STEP 3:
Call:
deposit(50)

---------------------------------------------------------

STEP 4:
Open transaction log section

---------------------------------------------------------

OBSERVE EVENTS:

- DepositStarted
- BalanceUpdated
- DepositCompleted

---------------------------------------------------------

STEP 5:
Call:
deposit(500)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
No events persist after revert.

---------------------------------------------------------

STEP 6:
Call:
validateNumber(50)

EXPECTED:
Revert

---------------------------------------------------------

OBSERVE:
ExecutionFailed event disappears too.

=========================================================
IMPORTANT INDEXED UNDERSTANDING
=========================================================

indexed parameters:

allow efficient filtering/searching.

---------------------------------------------------------

Example:

event Deposit(
    address indexed user,
    uint amount
)

---------------------------------------------------------

Frontend can efficiently search:
all events for specific user.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. MISSING EVENTS
---------------------------------------------------------

Critical actions not trackable.

---------------------------------------------------------
2. MISLEADING EVENTS
---------------------------------------------------------

Event says success,
but state update failed.

---------------------------------------------------------
3. EVENT BEFORE EXTERNAL CALL
---------------------------------------------------------

May create misleading logs.

---------------------------------------------------------
4. SENSITIVE DATA LEAKAGE
---------------------------------------------------------

Events are publicly visible forever.

=========================================================
GAS OBSERVATION
=========================================================

Events:
cost less gas than storage.

---------------------------------------------------------

Indexed fields:
slightly more expensive.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are critical actions logged?
- Do events match state changes?
- Can events mislead monitoring systems?
- Is sensitive data exposed?
- Are events emitted in correct order?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malformed event emitted before revert.

Off-chain bots incorrectly react.

---------------------------------------------------------

ANOTHER RISK

Missing liquidation event
prevents monitoring systems
from detecting dangerous activity.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Event emission order
2. State updates
3. Revert behavior
4. Off-chain monitoring assumptions
5. Event consistency

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add Withdraw event
2. Add AdminAction event
3. Emit event AFTER modifier execution
4. Add indexed tokenId field

BONUS:
Build mini ERC20-style Transfer event.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Events create blockchain logs
- Events help off-chain tracking
- Events are not contract storage
- Events disappear if transaction reverts
- indexed enables efficient searching
- Event ordering matters heavily
- Incorrect events may mislead systems
- Events are cheaper than storage
- Auditors verify event consistency
- Execution tracking is critical in smart contracts

=========================================================
*/
/*
Audit Report

Title: Event Emitted Before Input Validation

Severity: Low

Location:
Contract: EventExecutionTracking
Function: deposit()

Vulnerability Description:

The deposit() function emits the DepositStarted event
before validating the supplied amount.

Code:

emit DepositStarted(msg.sender, _amount);

require(_amount > 0, "Amount must be > 0");
require(_amount <= 100, "Amount too large");

This causes event emission logic to occur before
execution requirements are verified.

Although Ethereum removes all logs when a transaction
reverts, emitting events before validation is considered
poor design because it may create confusion during code
reviews and increases the risk of misleading event logic
if future modifications introduce external integrations.

Impact:

Current Impact:
- No state corruption
- No fund loss
- Reverted transactions remove emitted logs

Potential Future Impact:
- Misleading monitoring assumptions
- Poor event ordering
- Increased audit complexity
- Incorrect off-chain integrations

Proof of Concept:

1. User calls:

   deposit(500)

2. Contract executes:

   emit DepositStarted(...)

3. Validation fails:

   require(_amount <= 100)

4. Transaction reverts

5. Event is removed from final transaction logs

Observation:

Event execution occurred before validation checks.

Root Cause:

The function emits events before validating
user-controlled input.

Recommendation:

Perform all validation checks before emitting events.

Example:

require(_amount > 0);
require(_amount <= 100);

emit DepositStarted(msg.sender, _amount);

This ensures event ordering accurately reflects
successful execution flow.

Status: Confirmed

Risk Rating: Low

*/

// Patched code
contract EventExecutionTracking {

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;

    event DepositStarted(
        address indexed user,
        uint256 amount
    );

    event BalanceUpdated(
        address indexed user,
        uint256 newBalance
    );

    event DepositCompleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposits
    );

    function deposit(
        uint256 _amount
    )
        external
    {
        /*
            CHECKS FIRST
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        require(
            _amount <= 100,
            "Amount too large"
        );

        /*
            Emit only after validation succeeds.
        */
        emit DepositStarted(
            msg.sender,
            _amount
        );

        balances[msg.sender] += _amount;

        emit BalanceUpdated(
            msg.sender,
            balances[msg.sender]
        );

        totalDeposits += _amount;

        emit DepositCompleted(
            msg.sender,
            _amount,
            totalDeposits
        );
    }
}