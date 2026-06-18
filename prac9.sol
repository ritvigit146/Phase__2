// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Delete storage variable
CONCEPT: Reset behavior
=========================================================

OBJECTIVE

- Understand delete on storage variables
- Learn default reset values
- Observe how storage is cleared
- Understand delete behavior on arrays
- Think like auditor about reset logic

---------------------------------------------------------
CORE CONCEPT
---------------------------------------------------------

delete variable;

Resets variable to DEFAULT VALUE.

---------------------------------------------------------
DEFAULT VALUES
---------------------------------------------------------

uint256  => 0
bool     => false
address  => address(0)
string   => ""
array    => empty array

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

delete DOES NOT:
- erase blockchain history
- physically remove storage forever
- refund all gas automatically

It only resets current state values.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

delete is commonly used for:

- resetting balances
- clearing temporary state
- removing users
- resetting arrays
- invalidating data

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- improper reset logic
- delete ordering bugs
- array holes
- broken accounting
- stale storage references

=========================================================
*/
contract DeleteStorageVariableVul {

    uint256 public number = 100;
    bool public isActive = true;

    address public owner =
        0x1111111111111111111111111111111111111111;

    string public message = "Blockchain";

    uint256[] public numbers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        numbers.push(10);
        numbers.push(20);
        numbers.push(30);
    }

    function deleteNumber() public onlyOwner {
        delete number;
    }

    function deleteBool() public onlyOwner {
        delete isActive;
    }

    // Prevent accidental deletion of owner
    function deleteOwner() public onlyOwner {
        revert("Owner deletion not allowed");
    }

    function deleteMessage() public onlyOwner {
        delete message;
    }

    function deleteArray() public onlyOwner {
        delete numbers;
    }

    /*
     * Remove element without creating holes
     */
    function deleteArrayIndex(
        uint256 _index
    )
        public
        onlyOwner
    {
        require(
            _index < numbers.length,
            "Invalid index"
        );

        numbers[_index] =
            numbers[numbers.length - 1];

        numbers.pop();
    }

    function getArray()
        public
        view
        returns (uint256[] memory)
    {
        return numbers;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

number    = 100
isActive  = true
owner     = 0x111...
message   = "Blockchain"

numbers = [10,20,30]

---------------------------------------------------------

CALL:
deleteNumber()

EVM ACTIONS:

1. Storage slot located
2. Value reset to default
3. number becomes 0

---------------------------------------------------------

FINAL STATE

number = 0

=========================================================
DELETE BOOL FLOW
=========================================================

CALL:
deleteBool()

EXPECTED:

isActive = false

=========================================================
DELETE ADDRESS FLOW
=========================================================

CALL:
deleteOwner()

EXPECTED:

owner = address(0)

=========================================================
DELETE STRING FLOW
=========================================================

CALL:
deleteMessage()

EXPECTED:

message = ""

=========================================================
DELETE ARRAY FLOW
=========================================================

INITIAL ARRAY

[10,20,30]

---------------------------------------------------------

CALL:
deleteArray()

---------------------------------------------------------

FINAL ARRAY

[]

length = 0

=========================================================
DELETE ARRAY INDEX FLOW
=========================================================

INITIAL ARRAY

[10,20,30]

---------------------------------------------------------

CALL:
deleteArrayIndex(1)

---------------------------------------------------------

FINAL ARRAY

[10,0,30]

IMPORTANT:

Length remains 3.

delete only resets element value.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
number()

EXPECTED:
100

---------------------------------------------------------

STEP 3:
Call:
deleteNumber()

---------------------------------------------------------

STEP 4:
Call:
number()

EXPECTED:
0

=========================================================
ARRAY TESTING
=========================================================

STEP 1:
Call:
getArray()

EXPECTED:

[10,20,30]

---------------------------------------------------------

STEP 2:
Call:
deleteArrayIndex(1)

---------------------------------------------------------

STEP 3:
Call:
getArray()

EXPECTED:

[10,0,30]

---------------------------------------------------------

STEP 4:
Call:
deleteArray()

---------------------------------------------------------

STEP 5:
Call:
getArray()

EXPECTED:

[]

=========================================================
IMPORTANT STORAGE UNDERSTANDING
=========================================================

DELETE RESETS STORAGE SLOT
TO DEFAULT VALUE.

---------------------------------------------------------

EXAMPLE

BEFORE:

slotX => 100

AFTER delete:

slotX => 0

---------------------------------------------------------

FOR ARRAYS

delete array:
- resets length
- clears elements logically

delete array[index]:
- resets only one slot
- does NOT shrink array

=========================================================
GAS OBSERVATION
=========================================================

DELETE may provide partial gas refunds
for clearing storage slots.

However:
refund rules changed across Ethereum upgrades.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DELETE ORDERING BUGS
---------------------------------------------------------

Dangerous pattern:

delete balances[user];

totalSupply -= balances[user];

RESULT:
balances[user] already became 0

Accounting breaks.

---------------------------------------------------------
2. ARRAY HOLES
---------------------------------------------------------

delete array[index]

creates sparse arrays.

Risk:
- broken iteration logic
- unexpected zeros
- accounting bugs

---------------------------------------------------------
3. STALE REFERENCES
---------------------------------------------------------

Deleting value may not clean all references.

Other structures may still point to old data.

---------------------------------------------------------
4. FALSE ASSUMPTION
---------------------------------------------------------

delete DOES NOT erase blockchain history.

All old states remain permanently visible.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker abuses improper delete logic.

Example:
- reset balance before fee calculation
- bypass accounting checks
- exploit sparse arrays

---------------------------------------------------------

REAL-WORLD IMPACT

Many protocols suffered:
- accounting mismatches
- reward bugs
- broken iteration logic

due to incorrect reset behavior.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Array element removal shrinks array properly
2. No holes remain in array

EXAMPLE:

BEFORE:
[10,20,30]

Remove index 1

AFTER:
[10,30]

HINT:

Use:
- swap element with last value
- pop()

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- delete resets values to defaults
- delete does not erase blockchain history
- arrays behave differently from simple variables
- deleting array index creates holes
- storage reset order matters
- delete can break accounting logic
- auditors inspect cleanup behavior carefully
- sparse arrays create hidden bugs
- storage design affects security
- reset logic must be carefully audited

=========================================================
*/
// Patched code
contract ArrayRemovalFixed {
    uint256[] public numbers;

    function addNumber(uint256 _number) public {
        numbers.push(_number);
    }

    function remove(uint256 _index) public {
        require(_index < numbers.length, "Invalid index");

        // Move last element to the position being removed
        numbers[_index] = numbers[numbers.length - 1];

        // Remove last element and shrink array
        numbers.pop();
    }

    function getArray() public view returns (uint256[] memory) {
        return numbers;
    }
}