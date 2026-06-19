// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Compare storage vs memory updates
CONCEPT: Reference behavior
=========================================================

OBJECTIVE

- Learn difference between storage and memory updates
- Understand reference vs copy behavior
- Learn why storage changes persist
- Understand why memory changes disappear

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

STORAGE:
Creates direct reference to blockchain state.

MEMORY:
Creates temporary independent copy.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

STORAGE UPDATE:
Changes original blockchain data.

MEMORY UPDATE:
Changes temporary copy only.

---------------------------------------------------------
VERY IMPORTANT
---------------------------------------------------------

This is one of the MOST IMPORTANT
concepts in Solidity security.

Many real-world bugs happen because:
developers confuse memory and storage.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Understanding reference behavior is critical for:

- DeFi protocols
- token accounting
- staking systems
- governance logic
- NFT marketplaces
- upgradeable contracts

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is storage reference intentional?
- Is memory copy expected?
- Are mutations happening correctly?
- Can accidental state mutation occur?
- Is protocol logic silently failing?

=========================================================
*/
contract StorageVsMemoryVul {

    struct User {
        uint256 score;
        bool active;
    }

    mapping(address => User) public users;

    function createUser() public {

        users[msg.sender] = User({
            score: 100,
            active: true
        });
    }

    /*
     * VULNERABILITY:
     * No check that user exists before update.
     * Any address can modify its mapping entry
     * even without calling createUser().
     */
    function updateUsingStorage() public {

        User storage user = users[msg.sender];

        user.score = 999;
    }

    /*
     No validation that user exists.
     Reads default values if user was never created.
     */
    function updateUsingMemory()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User memory user = users[msg.sender];

        user.score = 555;
        user.active = false;

        return (
            user.score,
            user.active
        );
    }

    function getUser()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage user = users[msg.sender];

        return (
            user.score,
            user.active
        );
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
createUser()

STORAGE STATE:

{
    score: 100,
    active: true
}

---------------------------------------------------------

CALL:
updateUsingStorage()

EVM ACTIONS:

1. Storage reference created
2. user points directly to storage
3. user.score updated
4. Blockchain state modified permanently

---------------------------------------------------------

FINAL STORAGE STATE:

{
    score: 999,
    active: true
}

=========================================================

CALL:
updateUsingMemory()

EVM ACTIONS:

1. Storage struct copied into memory
2. user becomes temporary copy
3. Memory values modified
4. Storage remains untouched
5. Memory destroyed after execution

---------------------------------------------------------

MEMORY COPY:

{
    score: 555,
    active: false
}

---------------------------------------------------------

ACTUAL STORAGE STILL:

{
    score: 999,
    active: true
}

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
createUser()

---------------------------------------------------------

STEP 3:
Call:
getUser()

EXPECTED:
100, true

---------------------------------------------------------

STEP 4:
Call:
updateUsingStorage()

---------------------------------------------------------

STEP 5:
Call:
getUser()

EXPECTED:
999, true

OBSERVE:
Storage permanently updated.

---------------------------------------------------------

STEP 6:
Call:
updateUsingMemory()

EXPECTED RETURN:
555, false

---------------------------------------------------------

STEP 7:
Call:
getUser()

EXPECTED:
999, true

OBSERVE:
Storage remained unchanged.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Call updateUsingMemory() repeatedly

EXPECTED:
Storage never changes

---------------------------------------------------------

TEST:
Call updateUsingStorage() multiple times

EXPECTED:
Storage updates persist

---------------------------------------------------------

TEST:
Use different Remix accounts

EXPECTED:
Each address has isolated storage

=========================================================
IMPORTANT REFERENCE UNDERSTANDING
=========================================================

---------------------------------------------------------
STORAGE REFERENCE
---------------------------------------------------------

User storage user = users[msg.sender];

Creates POINTER.

Changes affect original storage.

---------------------------------------------------------
MEMORY COPY
---------------------------------------------------------

User memory user = users[msg.sender];

Creates INDEPENDENT COPY.

Changes affect only memory.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

MANY BUGS HAPPEN BECAUSE:

Developer expects:
storage update

But accidentally modifies:
memory copy

---------------------------------------------------------

RESULT:
Protocol logic silently fails.

=========================================================
GAS OBSERVATION
=========================================================

STORAGE WRITES:
Expensive

---------------------------------------------------------

MEMORY OPERATIONS:
Cheaper

---------------------------------------------------------

COPYING STORAGE TO MEMORY:
Still consumes gas

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MEMORY/STORAGE CONFUSION
---------------------------------------------------------

One of most common Solidity bug classes.

Auditors inspect:
- copy semantics
- reference behavior
- mutation expectations

---------------------------------------------------------
2. ACCIDENTAL STORAGE MUTATION
---------------------------------------------------------

Storage references may:
unexpectedly modify state.

---------------------------------------------------------
3. SILENT FAILURES
---------------------------------------------------------

Memory modifications may:
appear successful
but never persist.

---------------------------------------------------------
4. GAS RISKS
---------------------------------------------------------

Large copies from storage to memory
can become expensive.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Critical validation modifies memory copy
instead of storage.

Security state never updates.

Possible impact:
- bypassed restrictions
- broken accounting
- failed access control

---------------------------------------------------------

ANOTHER RISK

Unexpected storage references may:
modify balances unintentionally.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add memory array example
2. Add storage array example
3. Compare mutation behavior

BONUS:
Observe gas differences in Remix.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Storage creates direct reference
- Memory creates independent copy
- Storage updates persist permanently
- Memory updates disappear after execution
- Memory/storage confusion causes bugs
- Storage writes consume more gas
- Copying storage to memory costs gas
- Reference behavior critical in Solidity
- Many vulnerabilities come from wrong assumptions
- Auditors inspect mutation semantics carefully

=========================================================
*/
/*
Audit Report
Finding 1: Missing User Initialization Check

Severity: Low

Description:
updateUsingStorage() updates storage without verifying that the caller previously created a user profile.

Affected Function:

updateUsingStorage()

Impact:

Unauthorized creation of partially initialized records
Inconsistent application state
Potential logic errors in future upgrades

Recommendation:

Add:

require(user.active, "User does not exist");

before modifying storage.

Finding 2: Missing Event Emission

Severity: Informational

Description:
State-changing operations do not emit events.

Impact:

Harder off-chain tracking
Reduced transparency

Recommendation:
Emit events whenever users are created or updated
*/

//Patched code
contract StorageVsMemoryPatched {

    struct User {
        uint256 score;
        bool active;
    }

    mapping(address => User) public users;

    event UserCreated(address indexed user);
    event ScoreUpdated(
        address indexed user,
        uint256 oldScore,
        uint256 newScore
    );

    function createUser() public {

        require(
            !users[msg.sender].active,
            "User already exists"
        );

        users[msg.sender] = User({
            score: 100,
            active: true
        });

        emit UserCreated(msg.sender);
    }

    function updateUsingStorage() public {

        User storage user = users[msg.sender];

        require(
            user.active,
            "User does not exist"
        );

        uint256 oldScore = user.score;

        user.score = 999;

        emit ScoreUpdated(
            msg.sender,
            oldScore,
            user.score
        );
    }

    function updateUsingMemory()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage storedUser = users[msg.sender];

        require(
            storedUser.active,
            "User does not exist"
        );

        User memory user = storedUser;

        user.score = 555;
        user.active = false;

        return (
            user.score,
            user.active
        );
    }

    function getUser()
        public
        view
        returns (
            uint256,
            bool
        )
    {
        User storage user = users[msg.sender];

        require(
            user.active,
            "User does not exist"
        );

        return (
            user.score,
            user.active
        );
    }
}