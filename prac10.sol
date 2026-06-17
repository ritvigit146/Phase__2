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

contract DeleteMappingEntry {

    mapping(address => uint256) public balances;

    function setBalance(uint256 _amount) public {
        balances[msg.sender] = _amount;
    }

    function deleteMyBalance() public {
        delete balances[msg.sender];
    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
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

Title: Missing Event Logging for Whitelist Changes

Severity: Low because the issue does not directly lead to unauthorized access, fund loss, or privilege escalation.
 However, it reduces transparency, monitoring capabilities, and auditability of contract activity.

Location: Contract: WhitelistSystem

Functions:

* addToWhitelist()
* removeFromWhitelist()

Vulnerability Description:

The contract updates whitelist status without emitting events.

When a user is added or removed from the whitelist, the state changes occur silently:

whitelist[_user] = true;

delete whitelist[_user];

As a result, there is no on-chain log that records whitelist modifications.

Impact:

The absence of events may:

* Reduce transparency
* Make monitoring difficult
* Complicate frontend integrations
* Reduce auditability of administrative actions
* Make incident investigations more difficult

Users and administrators cannot easily track when addresses were added to or removed from the whitelist without inspecting storage directly.

Proof of Concept:

1. Deploy contract

2. Call:
   addToWhitelist(UserA)

3. Observe:
   UserA becomes whitelisted

4. Check transaction logs

5. Observe:
   No event emitted

6. Call:
   removeFromWhitelist(UserA)

7. Observe:
   UserA removed from whitelist

8. Check transaction logs

9. Observe:
   No event emitted for removal

Root Cause:

The contract updates storage directly without emitting events:

whitelist[_user] = true;

delete whitelist[_user];

No event definitions or event emissions exist to record whitelist modifications.

Recommendation:

Add event declarations and emit them whenever whitelist status changes.

Example:

event UserWhitelisted(address indexed user);
event UserRemoved(address indexed user);

function addToWhitelist(address _user) public onlyOwner {
whitelist[_user] = true;
emit UserWhitelisted(_user);
}

function removeFromWhitelist(address _user) public onlyOwner {
delete whitelist[_user];
emit UserRemoved(_user);
}

This improves transparency, monitoring, frontend integration, and overall auditability.
*/
//Patched code
contract WhitelistSystem {

    address public owner;

    // Whitelist mapping
    mapping(address => bool) public whitelist;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Add user to whitelist
    function addToWhitelist(address _user) public onlyOwner {
        whitelist[_user] = true;
    }

    // Remove user from whitelist
    function removeFromWhitelist(address _user) public onlyOwner {
        delete whitelist[_user];
    }

    // Check whitelist status
    function isWhitelisted(address _user)
        public
        view
        returns (bool)
    {
        return whitelist[_user];
    }
}