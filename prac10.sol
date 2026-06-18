// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete mapping entry
CONCEPT: Partial storage reset
=========================================================

OBJECTIVE

- Learn how delete works on mappings
- Understand partial storage reset behavior
- Learn how specific user data is cleared
- Understand mapping cleanup implications

---------------------------------------------------------
WHAT HAPPENS WHEN DELETING MAPPING ENTRY?
---------------------------------------------------------

Mappings store values per key.

Example:

balances[user1] => 100
balances[user2] => 500

Using:

delete balances[user1];

ONLY resets user1 value.

Other entries remain unchanged.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

delete on mapping:
- resets ONLY selected key
- does NOT remove entire mapping
- resets value to default

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

uint256 => 0
bool => false
address => address(0)

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Mapping deletion used for:

- removing balances
- revoking permissions
- resetting user state
- removing approvals
- clearing staking positions

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can attacker delete others' data?
- Is cleanup complete?
- Is authorization missing?
- Are stale references left behind?
- Can deletion break accounting?

=========================================================
*/
contract WhitelistVul {

    mapping(address => bool) public whitelist;

    function addToWhitelist() public {
        whitelist[msg.sender] = true;
    }

    function removeFromWhitelist() public {
        delete whitelist[msg.sender];
    }

    function isWhitelisted(address _user)
        public
        view
        returns (bool)
    {
        return whitelist[_user];
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

balances[user] => 0

because uint256 default value is zero.

---------------------------------------------------------

USER A CALLS:
setBalance(100)

RESULT:

balances[userA] = 100

---------------------------------------------------------

USER B CALLS:
setBalance(999)

RESULT:

balances[userB] = 999

---------------------------------------------------------

USER A CALLS:
deleteMyBalance()

EVM ACTIONS:

1. msg.sender identified
2. Mapping slot calculated
3. Value reset to default
4. balances[userA] becomes 0

IMPORTANT:
Only userA entry deleted.

---------------------------------------------------------

FINAL STATE

balances[userA] = 0
balances[userB] = 999

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Using Account 1

Call:
setBalance(100)

EXPECTED:
balances(Account1) => 100

---------------------------------------------------------

STEP 3:
Switch to Account 2

Call:
setBalance(500)

EXPECTED:
balances(Account2) => 500

---------------------------------------------------------

STEP 4:
Switch back to Account 1

Call:
deleteMyBalance()

EXPECTED:
balances(Account1) => 0

---------------------------------------------------------

STEP 5:
Check Account 2

EXPECTED:
balances(Account2) still equals 500

OBSERVE:
Only one mapping entry reset.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Delete non-existing entry

Call:
deleteMyBalance()

without setting value first.

EXPECTED:
Still equals 0

---------------------------------------------------------

TEST:
Repeated delete calls

EXPECTED:
No error occurs

---------------------------------------------------------

TEST:
Set value after delete

1. setBalance(100)
2. deleteMyBalance()
3. setBalance(777)

EXPECTED:
balances[msg.sender] => 777

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

MAPPING STORAGE BEHAVIOR

Mappings use hashed storage locations.

Example:

keccak256(key + slot)

determines storage position.

---------------------------------------------------------

DELETE OPERATION

delete balances[user];

internally behaves similar to:

balances[user] = 0;

for uint256 mappings.

---------------------------------------------------------

IMPORTANT:
Other mapping entries remain untouched.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. PARTIAL RESET SAFETY
---------------------------------------------------------

Current logic safely deletes
ONLY caller's own entry.

Using msg.sender is important.

---------------------------------------------------------
2. DANGEROUS VERSION
---------------------------------------------------------

Example dangerous function:

function deleteUser(address user)

without authorization.

Attackers could erase other users' data.

---------------------------------------------------------
3. ACCOUNTING RISKS
---------------------------------------------------------

Deleting balances incorrectly may:
- break accounting
- bypass checks
- manipulate rewards

Auditors verify:
- total balances remain correct
- cleanup logic safe

---------------------------------------------------------
4. STALE STATE ISSUES
---------------------------------------------------------

Deleting one mapping may not clean:
- related arrays
- indexes
- references

This causes inconsistent protocol state.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose mapping stores:

- staking balances
- whitelist access
- reward eligibility

Improper deletion may:
- remove user rights
- erase balances
- bypass restrictions

---------------------------------------------------------

ANOTHER RISK

If protocol tracks totals separately:

totalBalance may remain unchanged
after deletion.

Result:
Accounting inconsistency.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Store bool instead of uint256
2. Use mapping for whitelist system
3. Add removeFromWhitelist() function

BONUS:
Restrict deletion to owner only.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- delete resets mapping value to default
- Only targeted key is affected
- Other mapping entries remain unchanged
- Mappings use hashed storage
- delete behaves like assigning default value
- msg.sender protects user-specific data
- Incorrect deletion can break accounting
- Partial cleanup may leave stale state
- Access control is critical
- Auditors inspect deletion logic carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in Whitelist Management

Severity: Medium

Contract: WhitelistVul

Functions:

addToWhitelist()
removeFromWhitelist()
Vulnerability Description

The contract allows any user to add themselves to the whitelist by calling addToWhitelist().

There is no authorization mechanism to ensure that only a trusted administrator can manage whitelist membership.

Since whitelist status is commonly used to grant privileged access to sensitive functionality, unauthorized users may obtain permissions that were intended only for approved addresses.

Impact

An attacker can:

Add themselves to the whitelist
Gain access to restricted functions
Bypass whitelist-based security controls
Circumvent protocol access restrictions

If whitelist membership controls critical operations, this could lead to unauthorized actions within the protocol.

Proof of Concept
Initial State
whitelist[attacker] = false
Attacker Call
addToWhitelist();
Result
whitelist[attacker] = true

The attacker becomes whitelisted without any approval from the contract owner.

Root Cause

The function lacks access control.

function addToWhitelist() public {
    whitelist[msg.sender] = true;
}

Any caller can modify whitelist state for themselves.

Recommendation

Implement owner-based access control so that only the contract owner can add or remove whitelist members.

Example:

require(msg.sender == owner, "Only owner");

Apply this check to all whitelist management functions.
*/
//Patched code
contract Whitelist {

    mapping(address => bool) public whitelist;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addToWhitelist(address _user) public {
        require(msg.sender == owner, "Only owner");

        whitelist[_user] = true;
    }

    function removeFromWhitelist(address _user) public {
        require(msg.sender == owner, "Only owner");

        delete whitelist[_user];
    }

    function isWhitelisted(address _user)
        public
        view
        returns (bool)
    {
        return whitelist[_user];
    }
}