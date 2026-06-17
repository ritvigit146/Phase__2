// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete array item
CONCEPT: Sparse array behavior
=========================================================

OBJECTIVE

- Learn how delete works on arrays
- Understand sparse array creation
- Learn why delete does not shrink arrays
- Understand risks caused by empty slots

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Using:

delete array[index];

DOES NOT:
- remove index
- shift elements
- reduce array length

It ONLY resets value to default.

---------------------------------------------------------
EXAMPLE
---------------------------------------------------------

Before delete:

[5, 10, 15]

After:
delete numbers[1];

Result:

[5, 0, 15]

Length still = 3

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

uint256 => 0
bool => false
address => address(0)

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Can sparse arrays break logic?
- Are deleted entries handled safely?
- Does protocol incorrectly count empty slots?
- Can attackers abuse gaps?
- Is array cleanup implemented correctly?

=========================================================
*/
contract SparseArrayBehaviorVul {

    uint256[] public numbers;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    function deleteItem(uint256 _index) public {
        require(msg.sender == owner, "Not owner");
        require(_index < numbers.length, "Invalid index");

        delete numbers[_index];
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}
/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

numbers = []

---------------------------------------------------------

CALL:
addNumber(5)
addNumber(10)
addNumber(15)

ARRAY:

[5,10,15]

length = 3

---------------------------------------------------------

CALL:
deleteItem(1)

EVM ACTIONS:

1. EVM locates numbers[1]
2. Storage slot reset to default value
3. numbers[1] becomes 0

---------------------------------------------------------

FINAL ARRAY

[5,0,15]

IMPORTANT:
Length remains 3

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
addNumber(5)

---------------------------------------------------------

STEP 3:
Call:
addNumber(10)

---------------------------------------------------------

STEP 4:
Call:
addNumber(15)

---------------------------------------------------------

STEP 5:
Call:
getArray()

EXPECTED:
[5,10,15]

---------------------------------------------------------

STEP 6:
Call:
deleteItem(1)

---------------------------------------------------------

STEP 7:
Call:
getArray()

EXPECTED:
[5,0,15]

---------------------------------------------------------

STEP 8:
Call:
getLength()

EXPECTED:
3

OBSERVE:
Array size did not shrink.

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Delete first element

deleteItem(0)

EXPECTED:
First value becomes 0

---------------------------------------------------------

TEST:
Delete last element

deleteItem(2)

EXPECTED:
Last value becomes 0

---------------------------------------------------------

TEST:
Delete invalid index

deleteItem(999)

EXPECTED:
Transaction reverts

Reason:
Index out of bounds

---------------------------------------------------------

TEST:
Delete same index twice

EXPECTED:
No error

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

ARRAY STORAGE

Arrays store values sequentially.

Example:

slot0 => array length
slot1 => numbers[0]
slot2 => numbers[1]
slot3 => numbers[2]

---------------------------------------------------------

DELETE OPERATION

delete numbers[1];

ONLY resets value.

Storage layout remains same.

---------------------------------------------------------

IMPORTANT

delete does NOT:
- remove slot
- shift values
- reduce length

=========================================================
DELETE VS POP
=========================================================

---------------------------------------------------------
DELETE
---------------------------------------------------------

delete numbers[1];

Result:
[5,0,15]

length = 3

---------------------------------------------------------
POP
---------------------------------------------------------

numbers.pop();

Result:
[5,10]

length = 2

---------------------------------------------------------

pop() only removes LAST element.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. SPARSE ARRAY BUGS
---------------------------------------------------------

Sparse arrays may break:
- reward systems
- counting logic
- voting mechanisms
- iteration assumptions

---------------------------------------------------------
2. LOOP RISKS
---------------------------------------------------------

Loops may incorrectly process:
0 values as valid entries.

---------------------------------------------------------
3. STORAGE FRAGMENTATION
---------------------------------------------------------

Repeated delete operations create:
- fragmented storage
- inefficient arrays
- wasted gas

---------------------------------------------------------
4. BUSINESS LOGIC FAILURES
---------------------------------------------------------

If 0 is meaningful,
deleted entries may bypass validations.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose array stores active stakers.

Attacker deletes entries repeatedly.

Result:
- empty gaps created
- reward logic breaks
- participant counting fails

---------------------------------------------------------

REAL-WORLD ISSUE

Sparse arrays have caused:
- governance bugs
- staking calculation errors
- incorrect payout distribution

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Item is removed completely
2. Elements shift left
3. Array length decreases

Example:

Before:
[5,10,15]

Remove index 1

After:
[5,15]

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- delete resets value to default
- delete does NOT remove array index
- delete does NOT reduce length
- Sparse arrays contain gaps
- Arrays remain sequential in storage
- pop() differs from delete
- Sparse arrays may break protocol logic
- Invalid indexes revert
- Auditors inspect cleanup logic carefully
- Storage fragmentation affects efficiency

=========================================================
*/
/*
Audit Report

Title: Unrestricted Array Element Removal in removeItem()

Severity: Medium because any user can remove array elements, resulting in unauthorized modification of contract state.

Location:
Contract: SparseArrayBehaviorFixed
Function: removeItem()

Vulnerability Description:
The removeItem() function allows any user to remove any element from the array.

The function performs array modification and length reduction without verifying whether the caller is authorized.

As a result, any external account can delete stored values and alter the array structure.

Impact:
A user can:

* remove array entries without permission
* modify stored records
* disrupt business logic
* alter historical data
* interfere with application functionality

If the array represented:

* staking participants
* governance proposals
* voting records
* whitelist members
* reward recipients

then unauthorized removals could affect protocol integrity and lead to incorrect behavior.

Proof of Concept:

1. User adds values:

   addNumber(5)
   addNumber(10)
   addNumber(15)

2. Array becomes:

   [5,10,15]

3. Attacker calls:

   removeItem(1)

4. Transaction succeeds.

5. Elements shift left.

6. Array becomes:

   [5,15]

7. Stored data is modified by an unauthorized user.

Root Cause:
The function modifies storage directly:

for (uint256 i = _index; i < numbers.length - 1; i++) {
numbers[i] = numbers[i + 1];
}

numbers.pop();

without validating the caller's permissions.

Recommendation:
Restrict removal operations to the contract owner.

Example:

require(
msg.sender == owner,
"Not owner"
);

Status: Fixed

Fix Implemented:

address public owner;

constructor() {
owner = msg.sender;
}

function removeItem(uint256 _index) public {
require(
msg.sender == owner,
"Not owner"
);

```
require(
    _index < numbers.length,
    "Invalid index"
);

for (
    uint256 i = _index;
    i < numbers.length - 1;
    i++
) {
    numbers[i] = numbers[i + 1];
}

numbers.pop();
```

}

Result:

* Only the owner can remove elements.
* Unauthorized users cannot modify stored data.
* Array integrity is preserved.
* Elements are removed completely.
* Array length decreases correctly.
* Risk of malicious deletions is eliminated.

*/
// Patched code
contract SparseArrayBehaviorFixed {

    uint256[] public numbers;

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    function removeItem(uint256 _index) public {
        require(_index < numbers.length, "Invalid index");

        // Shift elements left
        for (uint256 i = _index; i < numbers.length - 1; i++) {
            numbers[i] = numbers[i + 1];
        }

        // Remove last element
        numbers.pop();
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }

    function getLength() public view returns (uint256) {
        return numbers.length;
    }
}