// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Modify storage through function
CONCEPT: State mutation
=========================================================

OBJECTIVE

- Learn how functions modify blockchain storage
- Understand state mutation in Solidity
- Learn difference between read and write operations
- Understand why state-changing functions cost gas

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

State mutation means:
changing contract storage.

Example:
- updating balances
- changing owner
- modifying configuration
- updating counters

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Functions that modify state:
- require transactions
- consume gas
- permanently change blockchain state

---------------------------------------------------------
VIEW VS STATE-CHANGING
---------------------------------------------------------

view function:
- reads storage only
- no state modification

non-view function:
- modifies storage
- changes blockchain state

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

State mutation is used in:

- token transfers
- staking systems
- ownership updates
- governance voting
- DeFi protocols
- NFT minting

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Who can mutate state?
- Is state updated safely?
- Can mutation corrupt protocol?
- Are validations missing?
- Is mutation atomic?

=========================================================
*/
contract StateMutationVul {

    uint256 public value;

    function updateValue(uint256 _newValue) public {
        value = _newValue;
    }

    function increaseValue(uint256 _amount) public {
        value = value + _amount;
    }

    function getValue() public view returns (uint256) {
        return value;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

value = 0

---------------------------------------------------------

CALL:
updateValue(100)

EVM ACTIONS:

1. Transaction reaches contract
2. _newValue arrives through calldata
3. Storage slot loaded
4. Storage updated
5. New state persisted

FINAL STATE:

value = 100

---------------------------------------------------------

CALL:
increaseValue(50)

BEFORE TX:
value = 100

EVM ACTIONS:

1. Current storage value read
2. Addition performed
3. Result written back to storage

AFTER TX:
value = 150

---------------------------------------------------------

CALL:
getValue()

RESULT:
Reads latest stored value.

No state mutation occurs.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

EXPECTED:
value() => 0

---------------------------------------------------------

STEP 2:
Call:
updateValue(100)

EXPECTED:
value() => 100

---------------------------------------------------------

STEP 3:
Call:
increaseValue(50)

EXPECTED:
value() => 150

---------------------------------------------------------

STEP 4:
Call:
increaseValue(1)

EXPECTED:
value() => 151

---------------------------------------------------------

STEP 5:
Refresh Remix

EXPECTED:
State persists permanently

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Set value to 0

EXPECTED:
State resets to zero

---------------------------------------------------------

TEST:
Increase by 0

EXPECTED:
No effective change

---------------------------------------------------------

TEST:
Use large uint256 values

EXPECTED:
Solidity ^0.8.x protects from overflow

---------------------------------------------------------

TEST:
Repeated mutations

EXPECTED:
Each transaction updates latest state

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

STATE MUTATION PROCESS

1. Read storage
2. Perform computation
3. Write updated value
4. Persist new state

---------------------------------------------------------

VERY IMPORTANT

Storage writes are expensive.

Reason:
Blockchain state changes permanently.

---------------------------------------------------------

TEMPORARY VS PERMANENT

Temporary computation:
- stack
- memory

Permanent data:
- storage

=========================================================
GAS OBSERVATION
=========================================================

READING STORAGE:
Cheaper

WRITING STORAGE:
Expensive

---------------------------------------------------------

Reason:
Storage updates modify blockchain state.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. ACCESS CONTROL
---------------------------------------------------------

Current issue:
ANYONE can mutate state.

Danger if variable controls:
- treasury
- fees
- rewards
- ownership

---------------------------------------------------------
2. INVALID STATE TRANSITIONS
---------------------------------------------------------

Auditors verify:
- state remains valid
- mutations follow protocol rules
- impossible states prevented

---------------------------------------------------------
3. OVERFLOW / UNDERFLOW
---------------------------------------------------------

Older Solidity versions vulnerable.

Solidity ^0.8.x automatically checks:
- overflow
- underflow

---------------------------------------------------------
4. PARTIAL STATE UPDATES
---------------------------------------------------------

Complex protocols may:
- update multiple variables
- fail midway
- create inconsistent state

Auditors inspect atomicity carefully.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose value controls protocol fee.

Attacker calls:

updateValue(0)

Result:
Protocol fees removed.

---------------------------------------------------------

ANOTHER ATTACK

Attacker repeatedly mutates storage
to manipulate:
- rewards
- voting
- balances
- protocol behavior

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Only owner can mutate state
2. Emit event after every mutation

BONUS:
Store previous value before update.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- State mutation changes blockchain storage
- Storage writes require transactions
- State-changing functions consume gas
- view functions only read state
- Storage persists permanently
- Mutations overwrite previous values
- Access control protects state
- Storage writes are expensive
- Solidity ^0.8.x prevents overflow
- Auditors inspect state transitions carefully

=========================================================
*/
//transaction cost
//depends on deployment and network
//execution cost
//depends on function called

/*
Audit Report

Title: Missing Access Control in State Mutation Functions

Severity: Medium because unauthorized users can modify persistent contract state

Location:
Contract: StateMutationVul
Functions:
- updateValue(uint256)
- increaseValue(uint256)

Vulnerability Description:

The functions updateValue() and increaseValue() are publicly accessible
without any authorization checks.

As a result, any external user can modify the value state variable,
causing unauthorized state mutations and overwriting legitimate data.

Impact:

An attacker can arbitrarily change the stored value.

If this variable controlled critical protocol logic such as:

- protocol fees
- reward calculations
- treasury parameters
- governance thresholds
- staking configuration

then unauthorized users could manipulate protocol behavior and
cause incorrect system operation.

Proof of Concept:

1. Deploy contract

2. User A calls:
   updateValue(100)

   Result:
   value = 100

3. Attacker calls:
   updateValue(0)

   Result:
   value = 0

4. Attacker calls:
   increaseValue(1000000)

   Result:
   value = 1000000

5. State changes successfully without restriction

Root Cause:

The functions are declared public and directly modify storage.

No access control mechanism exists to verify whether the caller
is authorized to perform state mutations.

Recommendation:

Restrict state-changing functions to an authorized owner.

Example:

require(msg.sender == owner, "Not owner");

Additionally:

- store previous values before updates
- emit events for state changes
- maintain an audit trail for mutations

*/
//Patched code
contract StateMutation {

    uint256 public value;
    uint256 public previousValue;

    address public owner;

    event ValueUpdated(
        uint256 oldValue,
        uint256 newValue
    );

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

    function updateValue(uint256 _newValue)
        public
        onlyOwner
    {
        previousValue = value;

        value = _newValue;

        emit ValueUpdated(
            previousValue,
            value
        );
    }

    function increaseValue(uint256 _amount)
        public
        onlyOwner
    {
        previousValue = value;

        value = value + _amount;

        emit ValueUpdated(
            previousValue,
            value
        );
    }

    function getValue()
        public
        view
        returns (uint256)
    {
        return value;
    }
}