// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare storage before/after tx
CONCEPT: State persistence
=========================================================

OBJECTIVE

- Learn how blockchain state changes after transactions
- Understand persistence of storage variables
- Compare state BEFORE and AFTER execution
- Learn why transactions permanently modify storage

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Before transaction:
Storage contains OLD state

After transaction:
Storage contains UPDATED state

Blockchain permanently stores
latest contract state.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Transactions:
- modify blockchain state
- consume gas
- persist changes permanently

view functions:
- only read state
- do NOT modify storage

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

State persistence is critical in:

- token balances
- staking systems
- ownership tracking
- DeFi protocols
- NFT ownership
- governance systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Was state updated correctly?
- Did transaction modify intended storage?
- Can state become corrupted?
- Is old state unexpectedly overwritten?
- Are updates atomic and safe?

=========================================================
*/
contract StatePersistenceVul {

    address public owner;

    uint256 public counter;
    uint256 public previousCounter;

    event CounterUpdated(
        uint256 oldValue,
        uint256 newValue
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can modify counter"
        );
        _;
    }

    function increment()
        public
        onlyOwner
    {
        previousCounter = counter;

        counter = counter + 1;

        emit CounterUpdated(
            previousCounter,
            counter
        );
    }

    function setCounter(uint256 _value)
        public
        onlyOwner
    {
        previousCounter = counter;

        counter = _value;

        emit CounterUpdated(
            previousCounter,
            counter
        );
    }

    function getCounter()
        public
        view
        returns (uint256)
    {
        return counter;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

counter = 0

Stored permanently in blockchain storage.

---------------------------------------------------------

CALL:
increment()

BEFORE TX:
counter = 0

EVM ACTIONS:

1. Transaction reaches contract
2. Current storage value loaded
3. counter + 1 calculated
4. Storage slot updated
5. New value persisted

AFTER TX:
counter = 1

---------------------------------------------------------

CALL:
increment()

BEFORE TX:
counter = 1

AFTER TX:
counter = 2

---------------------------------------------------------

CALL:
setCounter(100)

BEFORE TX:
counter = 2

AFTER TX:
counter = 100

---------------------------------------------------------

IMPORTANT OBSERVATION

State persists BETWEEN transactions.

Every new transaction sees
latest stored value.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

EXPECTED:
counter() => 0

---------------------------------------------------------

STEP 2:
Call:
increment()

EXPECTED:
counter() => 1

---------------------------------------------------------

STEP 3:
Call:
increment()

EXPECTED:
counter() => 2

---------------------------------------------------------

STEP 4:
Call:
setCounter(999)

EXPECTED:
counter() => 999

---------------------------------------------------------

STEP 5:
Refresh Remix UI

EXPECTED:
counter still equals 999

OBSERVE:
Storage persists permanently.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Set counter to 0

EXPECTED:
Storage resets to 0

---------------------------------------------------------

TEST:
Repeated transactions

increment()
increment()
increment()

EXPECTED:
Counter increases sequentially

---------------------------------------------------------

TEST:
Large uint256 values

EXPECTED:
Works correctly in Solidity ^0.8.x

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

STATE BEFORE TX

Storage contains previous blockchain state.

---------------------------------------------------------

STATE AFTER TX

Updated values become new permanent state.

---------------------------------------------------------

VERY IMPORTANT

Each transaction:
- reads current storage
- modifies storage
- commits updated state

---------------------------------------------------------

BLOCKCHAIN PERSISTENCE

Storage survives:
- new transactions
- page refreshes
- node restarts

=========================================================
EVM INTERNAL FLOW
=========================================================

increment()

1. Read counter from storage
2. Load into EVM stack
3. Perform addition
4. Write updated value back to storage
5. Persist state to blockchain

---------------------------------------------------------

counter variable lives in STORAGE.

Temporary computation happens in:
- stack
- memory

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. STATE CONSISTENCY
---------------------------------------------------------

Auditors verify:
- storage updated correctly
- no partial updates
- no unexpected overwrites

---------------------------------------------------------
2. RACE CONDITIONS
---------------------------------------------------------

Multiple users may update same state.

Auditors inspect:
- ordering issues
- stale reads
- transaction assumptions

---------------------------------------------------------
3. ACCESS CONTROL
---------------------------------------------------------

Current issue:
ANYONE can modify counter.

Danger if counter controls:
- protocol settings
- rewards
- treasury logic

---------------------------------------------------------
4. PERSISTENT STATE RISKS
---------------------------------------------------------

Bad state changes persist permanently.

Incorrect updates may:
- corrupt protocol
- lock funds
- break logic forever

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose counter tracks:
- reward multiplier
- treasury percentage
- governance threshold

Attacker calls:

setCounter(999999)

Impact:
Protocol behavior manipulated.

---------------------------------------------------------

ANOTHER RISK

Unexpected state persistence may:
- preserve malicious values
- maintain broken configuration
- cause long-term protocol damage

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Store previousCounter
2. Before every update:
   save old value

BONUS:
Emit event showing:
old value -> new value

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage persists across transactions
- Transactions permanently modify state
- view functions only read storage
- State before tx differs from after tx
- EVM reads then writes storage
- Storage updates consume gas
- Blockchain maintains latest state
- Incorrect state updates are dangerous
- Access control protects persistent state
- Auditors inspect state transitions carefully

=========================================================
*/
/*
Audit Report

Title: Loss of Previous State Due to Overwrite

Severity: Low

Status: Fixed

Location:
Contract: StatePersistence
Functions: increment(), setCounter()

Vulnerability Description:

In the vulnerable version, the counter state variable was
updated directly whenever increment() or setCounter()
was called.

As a result, the previous value was permanently lost and
could not be retrieved from contract storage.

This reduced auditability and made it difficult to track
historical state transitions.

Impact:

Loss of previous state values could:

* Reduce transparency
* Make debugging difficult
* Limit auditability
* Prevent recovery of historical information

If the variable represented critical protocol data,
important state history could be lost.

Proof of Concept:

Vulnerable Version:

1. Deploy contract

2. Call:
   setCounter(10)

   State:
   counter = 10

3. Call:
   setCounter(50)

   State:
   counter = 50

4. Observe:
   Previous value (10) is no longer stored.

Root Cause:

The previous implementation directly overwrote storage:

counter = _value;

without preserving the existing value.

Remediation:

The contract now stores the previous value before every
state update:

previousCounter = counter;

counter = _value;

Additionally, an event is emitted:

emit CounterUpdated(previousCounter, counter);

This provides:

* State history preservation
* Better auditability
* Easier debugging
* On-chain tracking of state transitions
*/
//Patched Code
contract StatePersistence {

    uint256 public counter;
    uint256 public previousCounter;

    // Event to track state changes
    event CounterUpdated(
        uint256 oldValue,
        uint256 newValue
    );

    function increment() public {

        // Save old value before update
        previousCounter = counter;

        counter = counter + 1;

        emit CounterUpdated(previousCounter, counter);
    }

    function setCounter(uint256 _value) public {

        // Save old value before update
        previousCounter = counter;

        counter = _value;

        emit CounterUpdated(previousCounter, counter);
    }

    function getCounter() public view returns (uint256) {

        return counter;
    }
}