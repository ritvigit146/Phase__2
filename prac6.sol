// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store struct data
CONCEPT: Complex storage layout
=========================================================

OBJECTIVE

- Learn how Solidity stores struct data
- Understand grouped data storage
- Learn complex storage organization
- Understand struct-related security concerns

---------------------------------------------------------
WHAT IS A STRUCT?
---------------------------------------------------------

A struct allows multiple variables
to be grouped together into one object.

Example:
A user may contain:
- name
- age
- wallet
- active status

Instead of separate variables,
struct combines them into one unit.

---------------------------------------------------------
REAL-WORLD USES
---------------------------------------------------------

Structs are heavily used in:

- user profiles
- staking positions
- NFT metadata
- order books
- voting systems
- DeFi positions
- marketplace listings

---------------------------------------------------------
IMPORTANT CONCEPT
---------------------------------------------------------

Struct data is stored sequentially
inside blockchain storage.

Each field occupies storage slots
depending on variable size.

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Is struct data initialized safely?
- Can users overwrite others' structs?
- Is stale data left behind?
- Is storage packing optimized?
- Are nested structs handled correctly?

=========================================================
*/
contract StructStorageVul {

    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }

    User public user;

    function storeUser(
        string memory _name,
        uint256 _age,
        address _wallet,
        bool _isActive
    ) public {
        user = User(_name, _age, _wallet, _isActive);
    }

    function getUser()
        public
        view
        returns (
            string memory,
            uint256,
            address,
            bool
        )
    {
        return (
            user.name,
            user.age,
            user.wallet,
            user.isActive
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

Struct fields contain default values:

name      => ""
age       => 0
wallet    => 0x0000000000000000000000000000000000000000
isActive  => false

---------------------------------------------------------

CALL:
storeUser("Imran", 25, 0x123..., true)

EVM ACTIONS:

1. Function parameters arrive via calldata
2. _name copied into memory
3. Struct object created temporarily
4. Struct fields written into storage
5. Existing struct data overwritten
6. Gas consumed for storage writes

---------------------------------------------------------

STORAGE RESULT

user.name      = "Imran"
user.age       = 25
user.wallet    = 0x123...
user.isActive  = true

---------------------------------------------------------

CALL:
getUser()

EVM:
1. Reads struct fields from storage
2. Returns all values

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:

storeUser(
    "Alice",
    30,
    <wallet address>,
    true
)

---------------------------------------------------------

STEP 3:
Call:
getUser()

EXPECTED:
- name = Alice
- age = 30
- wallet = provided address
- isActive = true

---------------------------------------------------------

STEP 4:
Store new user data

EXPECTED:
Old struct data overwritten completely

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Empty string

storeUser("", 0, address(0), false)

EXPECTED:
Works successfully

---------------------------------------------------------

TEST:
Overwrite struct multiple times

EXPECTED:
Latest values replace old values

---------------------------------------------------------

TEST:
Very large string input

OBSERVE:
Higher gas usage due to dynamic string storage

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

STRUCT STORAGE LAYOUT

Struct fields are stored sequentially.

Example layout:

slot0 => string reference/data
slot1 => age
slot2 => wallet + bool (possible packing)

---------------------------------------------------------

STORAGE PACKING

Smaller variables may share slots.

Example:
- bool
- uint8
- address

can sometimes pack together
to reduce gas usage.

---------------------------------------------------------

DYNAMIC TYPES

string is dynamic type.

Dynamic data requires:
- extra storage handling
- additional gas

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. COMPLETE OVERWRITE RISK
---------------------------------------------------------

Current logic replaces ENTIRE struct.

Danger:
Partial updates may accidentally erase fields.

---------------------------------------------------------
2. USER OWNERSHIP VALIDATION
---------------------------------------------------------

Current contract stores only one global user.

In real systems,
structs are often stored in mappings:

mapping(address => User)

Auditors verify:
- users cannot overwrite others' data
- ownership checks exist

---------------------------------------------------------
3. STORAGE BLOAT
---------------------------------------------------------

Large structs increase:
- gas cost
- deployment complexity
- execution cost

Auditors inspect:
- unnecessary fields
- inefficient storage layout

---------------------------------------------------------
4. DYNAMIC DATA RISKS
---------------------------------------------------------

Strings consume more gas.

Attackers may abuse:
- massive inputs
- storage flooding
- gas griefing

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose struct stores:

- KYC data
- admin config
- staking positions
- reward settings

Without access control,
attacker may overwrite entire struct.

---------------------------------------------------------

ANOTHER RISK

If partial updates are implemented incorrectly:

old values may unintentionally reset.

Example:
wallet becomes zero address accidentally.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Multiple users can store profiles
2. Use mapping(address => User)

BONUS:
Allow only msg.sender to modify own profile.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Structs group multiple variables together
- Structs are stored in blockchain storage
- Struct data persists permanently
- Struct updates overwrite old data
- Dynamic types consume more gas
- Storage packing affects optimization
- Strings require special storage handling
- Struct misuse can cause serious vulnerabilities
- Auditors inspect storage layout carefully
- Access control is critical for struct updates

=========================================================
*/
/*
Audit Report

Title: Global Struct Overwrite Due to Single Shared Storage

Severity: Medium

Location:
Contract: StructStorageVul
Function: storeUser()

Vulnerability Description

The contract stores all user information in a single global User struct:

User public user;

Any user calling storeUser() overwrites the entire existing struct stored in the contract.

As a result, multiple users cannot maintain separate profiles, and one user can replace data previously stored by another user.

Impact

An attacker or normal user can overwrite existing profile data.

If the struct contains important information such as:

KYC information
staking positions
reward configurations
admin settings
marketplace listings

then previously stored data can be permanently replaced.

This may lead to:

loss of user data
incorrect protocol state
unauthorized modification of records
disruption of application functionality
Proof of Concept
Deploy contract.
User A calls:
storeUser(
    "Alice",
    30,
    walletA,
    true
);

State:

name = Alice
age = 30
wallet = walletA
isActive = true
User B calls:
storeUser(
    "Bob",
    25,
    walletB,
    true
);
Contract state becomes:
name = Bob
age = 25
wallet = walletB
isActive = true
Alice's profile is completely overwritten.
Root Cause

The contract uses a single shared struct:

User public user;

All users write to the same storage location through:

user = User(_name, _age, _wallet, _isActive);

No user-specific storage mechanism exists.

Recommendation

Store profiles using a mapping so each address has isolated storage.

Example:

mapping(address => User) public users;

Store data using:

users[msg.sender] = User(
    _name,
    _age,
    _wallet,
    _isActive
);

Additionally, ensure users can only update their own profiles.
*/

//Patched code
contract StructStorage {

    struct User {
        string name;
        uint256 age;
        address wallet;
        bool isActive;
    }

    mapping(address => User) public users;

    function storeUser(
        string memory _name,
        uint256 _age,
        address _wallet,
        bool _isActive
    ) public {

        require(
            _wallet == msg.sender,
            "Can only store own profile"
        );

        users[msg.sender] = User(
            _name,
            _age,
            _wallet,
            _isActive
        );
    }

    function getMyProfile()
        public
        view
        returns (
            string memory,
            uint256,
            address,
            bool
        )
    {
        User memory user = users[msg.sender];

        return (
            user.name,
            user.age,
            user.wallet,
            user.isActive
        );
    }
}