// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call contract from contract
CONCEPT: Nested execution
=========================================================

OBJECTIVE

- Learn how one contract calls another
- Understand nested execution flow
- Learn msg.sender behavior across contracts
- Understand inter-contract trust assumptions

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Contracts can directly interact
with other deployed contracts.

---------------------------------------------------------

Execution may flow like:

User
   ->
Contract A
   ->
Contract B

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

During nested calls:

msg.sender changes.

---------------------------------------------------------

Inside Contract B:

msg.sender =
Contract A

NOT original user.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Modern Solidity systems are:

multi-contract architectures.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested calls appear in:

- ERC20 token interactions
- routers
- lending protocols
- staking systems
- NFT marketplaces
- bridges

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- execution flow
- msg.sender transitions
- trust assumptions
- nested state changes
- reentrancy windows

=========================================================
TARGET CONTRACT
=========================================================
*/

contract DataStorage {

    /*
        STORED VALUE
    */
    uint256 public storedNumber;

    /*
        TRACK LAST CALLER
    */
    address public lastCaller;

    /*
    =====================================================
    STORE NUMBER
    =====================================================
    */

    function setNumber(
        uint256 _number
    )
        external
    {

        /*
            Save input.
        */
        storedNumber = _number;

        /*
            Store msg.sender.

            IMPORTANT:
            This will become
            calling contract address
            during nested execution.
        */
        lastCaller = msg.sender;
    }

    /*
    =====================================================
    READ VALUE
    =====================================================
    */

    function getNumber()
        external
        view
        returns (uint256)
    {

        return storedNumber;
    }
}

/*
=========================================================
CALLER CONTRACT
=========================================================
*/

contract NestedCaller {

    /*
        TARGET CONTRACT
    */
    DataStorage public target;

    /*
        TRACK LOCAL EXECUTION
    */
    uint256 public localCounter;

    /*
        STORE LAST READ VALUE
    */
    uint256 public lastReadValue;

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        /*
            Save target contract reference.
        */
        target = DataStorage(_target);
    }

    /*
    =====================================================
    CALL TARGET CONTRACT
    =====================================================
    */

    function callSetNumber(
        uint256 _number
    )
        external
    {

        /*
            Local state update.
        */
        localCounter++;

        /*
            EXTERNAL CONTRACT CALL

            Execution jumps into:
            DataStorage.setNumber()
        */
        target.setNumber(_number);
    }

    /*
    =====================================================
    READ FROM TARGET CONTRACT
    =====================================================
    */

    function readTargetNumber()
        external
    {

        /*
            Nested external read.
        */
        uint256 value =
            target.getNumber();

        /*
            Save locally.
        */
        lastReadValue = value;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Constructor input:
DataStorage address

=========================================================
TRACE:
callSetNumber(100)
=========================================================

STEP 1:
User calls:

NestedCaller.callSetNumber(100)

=========================================================
STEP 2
=========================================================

NestedCaller executes:

localCounter++

---------------------------------------------------------

NEW VALUE:
1

=========================================================
STEP 3
=========================================================

External contract call:

target.setNumber(100)

---------------------------------------------------------

Execution CONTEXT switches.

=========================================================
STEP 4
=========================================================

Execution enters:
DataStorage contract

---------------------------------------------------------

storedNumber = 100

=========================================================
STEP 5
=========================================================

IMPORTANT:

Inside DataStorage:

msg.sender =
NestedCaller contract

---------------------------------------------------------

NOT original user.

=========================================================
STEP 6
=========================================================

lastCaller =
NestedCaller address

=========================================================
FINAL RESULT
=========================================================

---------------------------------------------------------
NestedCaller.localCounter
---------------------------------------------------------

1

---------------------------------------------------------
DataStorage.storedNumber
---------------------------------------------------------

100

---------------------------------------------------------
DataStorage.lastCaller
---------------------------------------------------------

NestedCaller address

=========================================================
IMPORTANT msg.sender UNDERSTANDING
=========================================================

FLOW:

User
   ->
NestedCaller
   ->
DataStorage

---------------------------------------------------------

Inside DataStorage:

msg.sender =
NestedCaller

=========================================================
WHY THIS IS IMPORTANT
=========================================================

Authentication logic may fail
if developer assumes:

msg.sender == original user

=========================================================
READ TRACE
=========================================================

CALL:
readTargetNumber()

=========================================================

STEP 1:
NestedCaller calls:

target.getNumber()

=========================================================
STEP 2
=========================================================

Execution enters:
DataStorage

---------------------------------------------------------

storedNumber returned.

=========================================================
STEP 3
=========================================================

Returned value saved:

lastReadValue = storedNumber

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy DataStorage

---------------------------------------------------------

STEP 2:
Deploy NestedCaller

Input:
DataStorage address

---------------------------------------------------------

STEP 3:
Call:
callSetNumber(100)

---------------------------------------------------------

STEP 4:
Open DataStorage

---------------------------------------------------------

STEP 5:
Call:
storedNumber()

EXPECTED:
100

---------------------------------------------------------

STEP 6:
Call:
lastCaller()

EXPECTED:
NestedCaller contract address

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

Nested execution changes:

---------------------------------------------------------
CONTROL FLOW
---------------------------------------------------------

and

---------------------------------------------------------
AUTHENTICATION CONTEXT
---------------------------------------------------------

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. msg.sender CONFUSION
---------------------------------------------------------

Authentication bypass possible.

---------------------------------------------------------
2. TRUST ASSUMPTIONS
---------------------------------------------------------

External contracts may behave maliciously.

---------------------------------------------------------
3. REENTRANCY
---------------------------------------------------------

Nested calls create callback opportunities.

---------------------------------------------------------
4. FAILURE PROPAGATION
---------------------------------------------------------

Nested revert breaks entire transaction.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers exploit:

- msg.sender assumptions
- nested callback logic
- external state assumptions
- recursive execution

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors trace:

- external jumps
- msg.sender changes
- storage mutations
- nested execution paths
- trust boundaries

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors build:

---------------------------------------------------------
EXECUTION GRAPH
---------------------------------------------------------

to understand:

- control flow
- state dependencies
- attack surface

=========================================================
WHY NESTED EXECUTION IS RISKY
=========================================================

More contracts =
more assumptions.

---------------------------------------------------------

More assumptions =
larger attack surface.

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add ETH transfers
2. Add low-level call()
3. Add failing nested call
4. Add malicious callback contract

BONUS:
Build mini router contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can call other contracts
- Nested execution changes msg.sender
- Execution context switches externally
- Nested calls increase complexity
- External calls create attack surface
- Authentication assumptions are dangerous
- Reverts propagate across nested calls
- Auditors trace execution flow carefully
- Multi-contract systems are harder to secure
- Inter-contract trust assumptions are critical

=========================================================
*/
/*
Audit Report

Title: No Security Vulnerability Detected in Nested Contract Call Example

Severity: Informational because the contract correctly demonstrates nested
execution and msg.sender behavior without introducing a security flaw.

Location:
Contract: DataStorage
Contract: NestedCaller

Vulnerability Description:

No security vulnerability was identified.

The contracts demonstrate how one contract calls another and how
msg.sender changes during nested execution.

When NestedCaller calls DataStorage.setNumber(), the msg.sender inside
DataStorage is the NestedCaller contract address, not the original user.
This is expected Solidity behavior and not a vulnerability.

Impact:

No direct security impact.

The contract functions as intended and correctly demonstrates:

- Nested external calls
- Execution context switching
- msg.sender transitions
- Inter-contract communication

Proof of Concept:

1. Deploy DataStorage.
2. Deploy NestedCaller using the DataStorage address.
3. Call:

   callSetNumber(100)

4. Observe:

   - DataStorage.storedNumber = 100
   - DataStorage.lastCaller = NestedCaller contract address
   - NestedCaller.localCounter = 1

The observed behavior matches Solidity's execution model.

Root Cause:

No vulnerability exists.

The change in msg.sender is an inherent feature of external contract
calls in Solidity. The contract does not misuse msg.sender for
authorization or access control.

Recommendation:

No security patch is required.

For production contracts:

- Do not assume msg.sender is always the original user after an external call.
- Implement explicit access control where authorization is required.
- Carefully review authentication logic in multi-contract architectures.

*/