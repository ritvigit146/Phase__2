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

    uint256 public storedNumber;
    address public lastCaller;

    function setNumber(uint256 _number) external {
        storedNumber = _number;
        lastCaller = msg.sender;
    }

    function getNumber() external view returns (uint256) {
        return storedNumber;
    }
}

contract NestedCaller {

    DataStorage public target;

    uint256 public localCounter;

    uint256 public lastReadValue;

    constructor(address _target) {

        require(_target != address(0), "Invalid target");

        require(
            _target.code.length > 0,
            "Target must be deployed contract"
        );

        target = DataStorage(_target);
    }

    function callSetNumber(uint256 _number) external {

        localCounter++;

        target.setNumber(_number);
    }

    function readTargetNumber() external {

        lastReadValue = target.getNumber();
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
contract NestedCaller {

constructor(address _target) {
    require(_target != address(0), "Invalid target");
    require(_target.code.length > 0, "Target is not a contract");

    target = DataStorage(_target);
}
    constructor(address _target) {

        require(_target != address(0), "Invalid target");

        require(
            _target.code.length > 0,
            "Target must be a deployed contract"
        );

        target = DataStorage(_target);
    }

    /*
        CALL TARGET CONTRACT
    */
    function callSetNumber(uint256 _number)
        external
    {
        localCounter++;

        target.setNumber(_number);
    }

    /*
        READ TARGET VALUE
    */
    function readTargetNumber()
        external
    {
        lastReadValue = target.getNumber();
    }
}