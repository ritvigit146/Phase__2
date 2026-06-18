// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use storage reference variable
CONCEPT: Direct storage pointer
=========================================================

OBJECTIVE

- Learn how storage reference variables work
- Understand direct pointers to storage
- Learn difference between storage and memory
- Understand how modifying storage references
  directly changes blockchain state

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

A storage reference variable points directly
to an existing storage location.

Example:

User storage user = users[id];

This does NOT create copy.

Instead:
user becomes POINTER to storage.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Modifying storage reference:

user.age = 50;

directly updates blockchain storage.

---------------------------------------------------------
STORAGE VS MEMORY
---------------------------------------------------------

STORAGE:
- permanent
- expensive
- modifies blockchain state
- acts like pointer/reference

MEMORY:
- temporary copy
- disappears after execution
- modifying memory does NOT update storage

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Storage references are heavily used in:

- DeFi protocols
- staking systems
- NFT marketplaces
- governance contracts
- user profile systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Are storage references intentional?
- Is accidental mutation possible?
- Are references pointing correctly?
- Is storage corruption possible?
- Is memory/storage confusion present?

=========================================================
*/
contract StorageReferenceVul {

    struct User {
        uint256 age;
        bool active;
    }

    mapping(address => User) public users;

    function createUser(uint256 _age) public {
        users[msg.sender] = User(_age, true);
    }

    function updateAge(uint256 _newAge) public {
        User storage user = users[msg.sender];

        user.age = _newAge;
    }

    function deactivateUser() public {
        User storage user = users[msg.sender];

        user.active = false;
    }

    function getMyData()
        public
        view
        returns (uint256, bool)
    {
        User storage user = users[msg.sender];

        return (user.age, user.active);
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

users[msg.sender]:

age = 0
active = false

---------------------------------------------------------

CALL:
createUser(25)

RESULT:

users[msg.sender]:
age = 25
active = true

---------------------------------------------------------

CALL:
updateAge(40)

EVM ACTIONS:

1. Mapping storage slot located
2. Storage reference created
3. user points directly to storage
4. user.age updated
5. Blockchain state mutated

---------------------------------------------------------

FINAL STATE

users[msg.sender]:
age = 40
active = true

---------------------------------------------------------

IMPORTANT

No copy created.

Storage reference directly modifies storage.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createUser(25)

---------------------------------------------------------

STEP 3:
Call:
getMyData()

EXPECTED:
25, true

---------------------------------------------------------

STEP 4:
Call:
updateAge(99)

---------------------------------------------------------

STEP 5:
Call:
getMyData()

EXPECTED:
99, true

OBSERVE:
Storage updated permanently.

---------------------------------------------------------

STEP 6:
Call:
deactivateUser()

EXPECTED:
99, false

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Update before createUser()

EXPECTED:
Works on default struct values

---------------------------------------------------------

TEST:
Repeated updates

EXPECTED:
Latest storage state persists

---------------------------------------------------------

TEST:
Different Remix accounts

EXPECTED:
Each address has isolated struct storage

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

THIS LINE:

User storage user = users[msg.sender];

creates STORAGE POINTER.

---------------------------------------------------------

VERY IMPORTANT

This is NOT copy:

User memory user = users[msg.sender];

would create temporary copy instead.

---------------------------------------------------------

STORAGE REFERENCE

Changes affect blockchain storage immediately.

---------------------------------------------------------

MEMORY COPY

Changes affect temporary copy only.

=========================================================
STORAGE VS MEMORY EXAMPLE
=========================================================

---------------------------------------------------------
STORAGE
---------------------------------------------------------

User storage user = users[msg.sender];

user.age = 50;

RESULT:
Blockchain storage updated.

---------------------------------------------------------
MEMORY
---------------------------------------------------------

User memory user = users[msg.sender];

user.age = 50;

RESULT:
Only temporary copy changes.

Original storage unchanged.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. ACCIDENTAL STORAGE MUTATION
---------------------------------------------------------

Developers may accidentally modify
real storage when expecting copy.

This causes unintended state changes.

---------------------------------------------------------
2. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

Very common Solidity bug source.

Auditors carefully inspect:
- reference types
- assignment behavior
- mutation side effects

---------------------------------------------------------
3. UNEXPECTED SIDE EFFECTS
---------------------------------------------------------

Changing storage references may:
- alter protocol state unexpectedly
- corrupt accounting
- bypass assumptions

---------------------------------------------------------
4. GAS CONSIDERATIONS
---------------------------------------------------------

Storage writes are expensive.

Unnecessary mutations waste gas.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Improper storage references may allow:
- accidental balance updates
- corrupted staking records
- unintended ownership changes

---------------------------------------------------------

REAL-WORLD RISK

Many Solidity bugs happen because:
developers expect copy
but receive storage reference instead.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add function using MEMORY copy
2. Change memory values
3. Observe storage remains unchanged

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- storage creates direct reference/pointer
- Storage references mutate blockchain state
- memory creates temporary copy
- Storage persists permanently
- Storage writes consume gas
- Reference types behave differently
- Memory/storage confusion causes bugs
- Structs inside mappings commonly use storage refs
- Storage references can create side effects
- Auditors inspect pointer behavior carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control and Unvalidated State Mutation via Storage Reference Usage

Severity: Medium because the issue is not a direct protocol-breaking or fund-stealing vulnerability, but a design-level permission/logic
 weakness that can become serious

Location:
Contract: StorageReferenceVul
Functions:
- createUser(uint256)
- updateAge(uint256)
- deactivateUser()

---------------------------------------------------------
Vulnerability Description:

The contract uses storage reference variables correctly from a Solidity
mechanics perspective, but lacks proper access control and state validation.

Any external user can:

- create a user profile for themselves with arbitrary age
- mutate their stored state without restriction
- deactivate their own account at will

While storage references themselves are not a vulnerability,
their unrestricted use allows uncontrolled state mutation.

---------------------------------------------------------
Impact:

An attacker or malicious user can:

- Create unlimited fake or spam user entries
- Inflate or manipulate user-related logic if age is used in:
  - rewards systems
  - governance weight
  - eligibility checks
- Continuously toggle or corrupt their own state
- Exploit business logic assumptions relying on valid user lifecycle

If integrated into a larger protocol, this can lead to:

- reward manipulation
- incorrect user scoring
- broken eligibility logic
- accounting inconsistencies

---------------------------------------------------------
Proof of Concept:

1. Attacker calls:
   createUser(999)

   Result:
   users[msg.sender] = { age: 999, active: true }

2. Attacker calls:
   updateAge(1)

   Result:
   age is reduced to manipulate eligibility/rewards logic

3. Attacker calls:
   deactivateUser()

   Result:
   user state becomes inactive

4. Attacker repeats cycles freely without restriction

---------------------------------------------------------
Root Cause:

- No access control or role restriction on state-changing functions
- No validation of user lifecycle state transitions
- No constraints on age updates or user creation rules
- Direct use of storage references without business logic safeguards

---------------------------------------------------------
Recommendation:

1. Add access control where necessary:
   - restrict user creation (e.g., onlyOwner or whitelist)
   - prevent arbitrary repeated overwrites if business logic requires immutability

2. Add state validation:
   require(user.age == 0) before createUser (if one-time creation is expected)

3. Add lifecycle protection:
   prevent re-activation or repeated creation if not intended

4. Emit events for all state changes for auditability

Example fix pattern:

require(!users[msg.sender].active, "Already exists");

---------------------------------------------------------
Note:

This is NOT a vulnerability in storage reference usage itself.

The risk comes from:
- unrestricted state mutation
- lack of business logic constraints
- missing access control

Storage references only expose how easily state can be modified,
which increases the impact of logic design flaws.
*/
//Patched code
contract StorageReference {

    struct User {
        uint256 age;
        bool active;
    }

    mapping(address => User) public users;

    address public owner;

    event UserCreated(
        address indexed user,
        uint256 age
    );

    event AgeUpdated(
        address indexed user,
        uint256 oldAge,
        uint256 newAge
    );

    event UserDeactivated(
        address indexed user
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

    function createUser(
        address _user,
        uint256 _age
    )
        public
        onlyOwner
    {
        require(_age > 0, "Invalid age");

        users[_user] = User(_age, true);

        emit UserCreated(_user, _age);
    }

    function updateAge(uint256 _newAge) public {
        User storage user = users[msg.sender];

        require(
            user.active,
            "User not active"
        );

        require(
            _newAge > 0,
            "Invalid age"
        );

        uint256 oldAge = user.age;

        user.age = _newAge;

        emit AgeUpdated(
            msg.sender,
            oldAge,
            _newAge
        );
    }

    function deactivateUser() public {
        User storage user = users[msg.sender];

        require(
            user.active,
            "Already inactive"
        );

        user.active = false;

        emit UserDeactivated(
            msg.sender
        );
    }

    // Demonstrates memory copy
    function previewAgeIncrease(
        uint256 _newAge
    )
        public
        view
        returns (uint256)
    {
        User memory user =
            users[msg.sender];

        user.age = _newAge;

        return user.age;
    }

    function getMyData()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage user =
            users[msg.sender];

        return (
            user.age,
            user.active
        );
    }
}