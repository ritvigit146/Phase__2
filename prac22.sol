// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use memory struct
CONCEPT: Temporary structs
=========================================================

OBJECTIVE

- Learn how memory structs work
- Understand temporary struct allocation
- Learn difference between memory structs and storage structs
- Understand temporary object lifecycle

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Memory structs:
- exist temporarily
- live only during execution
- disappear after function ends

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Memory structs do NOT persist
on blockchain storage.

They are useful for:
- temporary calculations
- data transformation
- returning grouped data
- processing information safely

---------------------------------------------------------
MEMORY STRUCT VS STORAGE STRUCT
---------------------------------------------------------

MEMORY STRUCT:
- temporary
- isolated copy
- cheaper
- disappears after execution

STORAGE STRUCT:
- permanent
- stored on blockchain
- expensive
- persists forever

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Memory structs used in:

- temporary user objects
- order processing
- calculations
- validation logic
- returned API-style responses

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is struct temporary or persistent?
- Is developer expecting storage mutation?
- Are copies handled safely?
- Are references intentional?
- Can large structs waste gas?

=========================================================
*/
contract MemoryStructExampleVul {

    struct User {
        string name;
        uint256 age;
        bool active;
    }

    User public storedUser;

    function createMemoryStruct()
        public
        pure
        returns (
            string memory,
            uint256,
            bool
        )
    {
        User memory tempUser = User({
            name: "Alice",
            age: 25,
            active: true
        });

        return (
            tempUser.name,
            tempUser.age,
            tempUser.active
        );
    }

    // Vulnerability:
    // Anyone can overwrite persistent state
    function storeUser(
        string memory _name,
        uint256 _age,
        bool _active
    )
        public
    {
        storedUser = User({
            name: _name,
            age: _age,
            active: _active
        });
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createMemoryStruct()

EVM ACTIONS:

1. Temporary memory allocated
2. Struct created in memory
3. Values assigned
4. Data returned
5. Memory cleared after execution

---------------------------------------------------------

IMPORTANT

tempUser does NOT persist permanently.

---------------------------------------------------------

CALL:
createAndModifyMemoryStruct()

INITIAL MEMORY STRUCT:

{
    name: "Bob",
    age: 30,
    active: true
}

---------------------------------------------------------

AFTER MODIFICATION:

{
    name: "Bob",
    age: 99,
    active: false
}

---------------------------------------------------------

AFTER FUNCTION ENDS:
Memory struct destroyed.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createMemoryStruct()

EXPECTED:
"Alice", 25, true

---------------------------------------------------------

STEP 3:
Call:
createAndModifyMemoryStruct()

EXPECTED:
"Bob", 99, false

---------------------------------------------------------

STEP 4:
Call:
storedUser()

EXPECTED:
Empty/default values

OBSERVE:
Memory structs did NOT persist.

---------------------------------------------------------

STEP 5:
Call:
storeUser()

---------------------------------------------------------

STEP 6:
Call:
storedUser()

EXPECTED:
"Charlie", 40, true

OBSERVE:
Storage struct persists permanently.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Modify memory struct repeatedly

EXPECTED:
Fresh struct created each execution

---------------------------------------------------------

TEST:
Use empty strings

EXPECTED:
Works correctly

---------------------------------------------------------

TEST:
Large struct data

OBSERVE:
More memory allocation
= higher gas usage

=========================================================
IMPORTANT MEMORY UNDERSTANDING
=========================================================

THIS CREATES MEMORY STRUCT:

User memory tempUser

---------------------------------------------------------

STRUCT EXISTS ONLY:
during function execution.

---------------------------------------------------------

AFTER EXECUTION:
Memory cleared automatically.

---------------------------------------------------------

VERY IMPORTANT

Memory structs:
do NOT persist on blockchain.

=========================================================
MEMORY STRUCT MUTABILITY
=========================================================

MEMORY STRUCTS ARE MUTABLE

Example:

tempUser.age = 99;

---------------------------------------------------------

HOWEVER:
Changes remain temporary only.

=========================================================
MEMORY VS STORAGE STRUCT
=========================================================

---------------------------------------------------------
MEMORY STRUCT
---------------------------------------------------------

Temporary

Cheap

Destroyed after execution

---------------------------------------------------------
STORAGE STRUCT
---------------------------------------------------------

Permanent

Expensive

Stored on blockchain forever

=========================================================
GAS OBSERVATION
=========================================================

MEMORY STRUCTS:
Cheaper than storage

---------------------------------------------------------

LARGE STRUCTS:
Still increase memory cost

---------------------------------------------------------

STORAGE WRITES:
Most expensive operations

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Common Solidity bug source.

Developers may think:
memory modifications persist.

They do NOT.

---------------------------------------------------------
2. COPY ASSUMPTIONS
---------------------------------------------------------

Auditors verify:
whether struct is:
- temporary copy
OR
- storage reference

---------------------------------------------------------
3. LARGE MEMORY STRUCTS
---------------------------------------------------------

Huge structs may:
- waste gas
- increase execution cost

---------------------------------------------------------
4. SILENT LOGIC FAILURES
---------------------------------------------------------

Protocol may expect:
storage mutation

but only memory updated.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Developer modifies memory struct
expecting permanent update.

Critical state never changes.

Possible impact:
- broken access control
- failed accounting
- incorrect balances

---------------------------------------------------------

ANOTHER RISK

Attacker supplies huge struct data.

Result:
high gas consumption.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Copy storage struct into memory
2. Modify memory copy
3. Show storage remains unchanged

BONUS:
Compare:
memory struct vs storage struct behavior

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Memory structs are temporary
- Memory structs disappear after execution
- Memory structs are mutable
- Storage structs persist permanently
- Memory changes do not affect storage
- Memory cheaper than storage
- Large structs increase gas usage
- Copy/reference confusion causes bugs
- Structs group related data together
- Auditors inspect struct semantics carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in storeUser()

Severity: Medium because unauthorized users can modify
persistent protocol state stored within the User struct.

Location:
Contract: MemoryStructExampleVul
Function: storeUser()

Vulnerability Description:

The storeUser() function allows any external user
to overwrite the storedUser state variable.

Since storedUser is a storage struct, modifications
persist permanently on the blockchain.

An attacker can replace legitimate user information
with arbitrary values.

Impact:

- Unauthorized state modification
- Data integrity loss
- Incorrect protocol records
- Potential manipulation of business logic
- Loss of trust in stored data

Proof of Concept:

1. Deploy contract

2. Owner calls:

   storeUser(
       "Charlie",
       40,
       true
   )

3. storedUser contains:

   {
       name: "Charlie",
       age: 40,
       active: true
   }

4. Attacker calls:

   storeUser(
       "Attacker",
       999,
       false
   )

5. storedUser becomes:

   {
       name: "Attacker",
       age: 999,
       active: false
   }

6. State modification succeeds

Root Cause:

The function is declared public and performs
a storage write without validating the caller.

No authorization mechanism restricts access
to privileged state-changing operations.

Recommendation:

Restrict access using ownership validation.

Example:

address public owner;

modifier onlyOwner() {
    require(
        msg.sender == owner,
        "Not owner"
    );
    _;
}

function storeUser(...)
    public
    onlyOwner
{
    ...
}

Patch Status:

Fixed.

The patched contract introduces:

- Owner variable
- onlyOwner modifier
- Authorization checks
- Protection against unauthorized writes

Patched Validation:

require(
    msg.sender == owner,
    "Not owner"
);

This ensures only authorized users can
modify the persistent User struct.

*/

//Patched code
contract MemoryStructExample {

    struct User {
        string name;
        uint256 age;
        bool active;
    }

    User public storedUser;

    address public owner;

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

    function createMemoryStruct()
        public
        pure
        returns (
            string memory,
            uint256,
            bool
        )
    {
        User memory tempUser = User({
            name: "Alice",
            age: 25,
            active: true
        });

        return (
            tempUser.name,
            tempUser.age,
            tempUser.active
        );
    }

    function storeUser(
        string memory _name,
        uint256 _age,
        bool _active
    )
        public
        onlyOwner
    {
        storedUser = User({
            name: _name,
            age: _age,
            active: _active
        });
    }
}