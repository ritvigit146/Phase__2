// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store uint in state variable
CONCEPT: Persistent blockchain state
=========================================================

OBJECTIVE

- Learn how Solidity stores data permanently on-chain
- Understand state variables and storage
- Learn how storage updates consume gas
- Understand why unrestricted writes are dangerous

---------------------------------------------------------
STORAGE UNDERSTANDING
---------------------------------------------------------

STATE VARIABLE:
- Stored permanently on blockchain
- Lives in contract storage
- Costs gas to modify
- Persists across transactions

DEFAULT VALUE:
uint256 => 0

AUDITOR FOCUS:
- Who can modify storage?
- Is access control missing?
- Can attackers overwrite values?
- Are unnecessary storage writes happening?

=========================================================
*/

contract StoreUintVul {

    uint256 public number;
    function storeNumber(uint256 _newNumber) public {
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL: storeNumber(100)

1. Transaction sent to blockchain
2. _newNumber arrives through calldata
3. EVM executes storage write
4. Storage slot updated permanently
5. Gas consumed
6. Blockchain state changes

---------------------------------------------------------

CALL: getNumber()

1. EVM reads value from storage
2. Returns current value
3. No state modification
4. No transaction required for external read

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

1. Deploy contract
2. Call number()
   EXPECTED => 0

3. Call:
   storeNumber(100)

4. Call:
   number()

   EXPECTED => 100

---------------------------------------------------------

EDGE CASES

Test:
storeNumber(0)

EXPECTED:
Works correctly

---------------------------------------------------------

Test:
storeNumber(type(uint256).max)

EXPECTED:
Largest uint256 stored successfully

=========================================================
FAILURE / SECURITY OBSERVATION
=========================================================

PROBLEM:
Anyone can modify number.

ATTACK:
Another wallet can call:
storeNumber(999999)

REAL-WORLD RISK:
If this variable controlled:
- token price
- protocol config
- treasury amount

then attacker could manipulate protocol behavior.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so only owner can update number.

HINT:
- Create owner variable
- Use constructor
- Add require(msg.sender == owner)

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- State variables use storage
- Storage is persistent
- Storage writes cost gas
- view functions only read data
- Public variables create getter functions
- calldata stores function inputs
- Missing access control is dangerous

=========================================================
*/
//transaction cost
//43718 gas
//execution cost
//22514 gas
/*
Audit Report
Title: Missing Access Control in storeNumber()

Severity: Medium because unauthorized users can modify protocol state

Location: Contract:StoreUintVul
Function: storeNumber()

Vulnerability Description: The storeNumber() function allows any external user to modify
the number state variable because no access control mechanism is implemented.

Impact:An attacker can overwrite the stored value with arbitrary data

If this variable controlled critical protocol logic such as:
- pricing
- treasury configuration
- protocol parameters

then unauthorized users could manipulate system behavior.

Proof of Concept:
                1. Deploy contract
                2. User A calls:
                    storeNumber(100)
                3. Attacker calls:
                    storeNumber(999999)
                4. Contract state changes successfully

Root Cause: The function is declared public without any authorization checks.
            No require() statement validates the caller identity.

Recommendation: Restrict access using an owner check.
                Example:
                require(msg.sender == owner, "Not owner");

*/
/*
Audit Report

Title: Unbounded Array Processing and Missing Empty Array Validation

Severity: Low because attackers can trigger unnecessary transaction failures
and excessive gas consumption, but cannot steal funds or gain privileges.

Location:
Contract: CalldataVsMemoryVulnerable

Functions:
- modifyMemory()
- saveValues()

Vulnerability Description:

The contract accepts user-controlled dynamic arrays without validating
their size.

In modifyMemory(), the function directly accesses tempArray[0]
without verifying that the array contains at least one element.

If an empty array is supplied, the transaction reverts due to an
out-of-bounds array access.

Additionally, saveValues() processes an unbounded user-supplied array
inside a loop and writes every element to storage.

A malicious user can provide an extremely large array, causing excessive
gas consumption and potential transaction failure.

Impact:

1. Empty Array Revert

Users can cause modifyMemory() to revert by supplying an empty array.

2. Excessive Gas Consumption

Attackers can submit very large arrays causing:

- expensive execution
- transaction failure
- reduced scalability
- denial of service for large operations

Proof of Concept:

1. Deploy contract

2. Call:

    modifyMemory([])

3. Function attempts:

    tempArray[0] = 999;

4. Transaction reverts due to
   array out-of-bounds access.


1. Deploy contract

2. Call:

    saveValues([1,2,3,... thousands of values])

3. Loop executes for every element

4. Gas consumption increases significantly

5. Transaction may fail because of gas limits

Root Cause:

1. modifyMemory()

The function assumes that the array contains at least one element.

No validation exists before accessing:

    tempArray[0]

2. saveValues()

The function performs an unbounded loop over
attacker-controlled input.

No limit exists on:

    _numbers.length

Recommendation:

Validate that the array is not empty before
modifying its first element.

Example:

    require(_numbers.length > 0, "Empty array");

Restrict maximum array size to prevent excessive
gas consumption.

Example:

    require(
        _numbers.length <= 100,
        "Array too large"
    );

*/

//patched code
contract StoreUint {

    uint256 public number;
    address public owner;

    constructor(){
        owner=msg.sender;
    }

    function storeNumber(uint256 _newNumber) public {
        require(msg.sender==owner,"Only owner can store number");
        number = _newNumber;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}