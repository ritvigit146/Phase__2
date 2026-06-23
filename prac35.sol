// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Validate calldata input manually
CONCEPT: Input security
=========================================================

OBJECTIVE

- Learn how to validate external calldata inputs
- Understand why all external input is untrusted
- Learn manual validation techniques
- Understand security risks from unchecked input

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

ALL calldata input is attacker-controlled.

Never trust:
- numbers
- addresses
- arrays
- strings
- booleans

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Without validation:
attackers may:
- break logic
- bypass rules
- exhaust gas
- corrupt accounting

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Input validation is one of the MOST IMPORTANT
smart contract security practices.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Validation used in:

- token transfers
- staking systems
- governance voting
- DeFi routers
- NFT minting
- access control

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Missing require() checks
- Unbounded arrays
- Invalid addresses
- Overflow assumptions
- Authorization validation
- Business logic validation

=========================================================
*/
contract ValidateNestedArrayVul {

    function processNestedArray(
        uint256[][] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        uint256 total;

        for (uint256 i = 0; i < _numbers.length; i++) {

            for (uint256 j = 0; j < _numbers[i].length; j++) {

                total += _numbers[i][j];
            }
        }

        return total;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
deposit(100)

EVM ACTIONS:

1. Input arrives in calldata
2. require() validation checks run
3. Validation passes
4. Storage updated permanently

---------------------------------------------------------

FINAL STORAGE:

storedAmount = 100

=========================================================

CALL:
deposit(0)

EVM ACTIONS:

1. Input arrives
2. require() fails
3. Transaction reverts
4. State unchanged

---------------------------------------------------------

ERROR:

"Amount must be > 0"

=========================================================

CALL:
processArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Array length validated
3. Loop validates each element
4. Total calculated
5. Result returned

---------------------------------------------------------

RESULT:
6

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

EXPECTED:
Success

---------------------------------------------------------

STEP 3:
Call:
deposit(0)

EXPECTED:
Revert

---------------------------------------------------------

STEP 4:
Call:
setReceiver(address(0))

EXPECTED:
Revert

---------------------------------------------------------

STEP 5:
Call:
processArray([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 6:
Call:
processArray([1,0,3])

EXPECTED:
Revert

---------------------------------------------------------

STEP 7:
Call:
validateMessage("Hello")

EXPECTED:
true

---------------------------------------------------------

STEP 8:
Call:
validateMessage("")

EXPECTED:
Revert

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Very large arrays

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Huge numbers

EXPECTED:
Rejected if above limit

---------------------------------------------------------

TEST:
Zero addresses

EXPECTED:
Rejected

---------------------------------------------------------

TEST:
Very long strings

EXPECTED:
Rejected

=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

ALL EXTERNAL INPUT IS:

- attacker-controlled
- untrusted
- potentially malicious

---------------------------------------------------------

NEVER ASSUME:
inputs are safe.

=========================================================
COMMON VALIDATION CHECKS
=========================================================

---------------------------------------------------------
NUMBERS
---------------------------------------------------------

- > 0
- within limits
- no overflow assumptions

---------------------------------------------------------
ADDRESSES
---------------------------------------------------------

- not zero address
- authorized user
- expected contract

---------------------------------------------------------
ARRAYS
---------------------------------------------------------

- max length
- valid elements
- bounded loops

---------------------------------------------------------
STRINGS
---------------------------------------------------------

- non-empty
- max length

=========================================================
WHY VALIDATION MATTERS
=========================================================

WITHOUT VALIDATION:

Attackers may:
- trigger DOS
- bypass logic
- corrupt state
- break accounting

=========================================================
GAS OBSERVATION
=========================================================

MORE VALIDATION:
More gas

---------------------------------------------------------

BUT:
Security is more important
than minimal gas savings.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. MISSING VALIDATION
---------------------------------------------------------

Most common vulnerability class.

---------------------------------------------------------
2. DOS VIA LARGE INPUTS
---------------------------------------------------------

Huge arrays may:
- exhaust gas
- break loops

---------------------------------------------------------
3. ZERO ADDRESS RISKS
---------------------------------------------------------

May:
- burn funds
- break ownership logic

---------------------------------------------------------
4. BUSINESS LOGIC VALIDATION
---------------------------------------------------------

Auditors inspect:
whether protocol rules
are enforced correctly.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker sends:
- massive arrays
- zero addresses
- invalid values
- unexpected inputs

Without validation:
protocol behavior breaks.

---------------------------------------------------------

REAL-WORLD IMPACT

Many exploits occurred because:
developers trusted external input.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Validate nested calldata arrays
2. Reject arrays larger than 50x50
3. Reject duplicate values

BONUS:
Add custom errors instead of require strings.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- All calldata is attacker-controlled
- External input must be validated
- require() enforces rules
- Arrays need size limits
- Addresses need zero-address checks
- Strings need length validation
- Validation prevents DOS and logic bugs
- Security more important than tiny gas savings
- Untrusted input is a major attack surface
- Auditors inspect validation carefully

=========================================================
*/
/*
Audit Report

Title: Missing Validation for Nested Calldata Arrays

Severity: Medium because attackers can submit oversized
nested arrays or duplicate values, leading to excessive gas
consumption and violation of business rules.

Location:
Contract: ValidateNestedArrayVul
Function: processNestedArray()

Vulnerability Description:

The processNestedArray() function accepts a nested calldata
array but does not validate:

- maximum number of rows
- maximum number of elements per row
- duplicate values

Because all calldata is attacker-controlled, a malicious
user can submit excessively large nested arrays that force
the contract to perform a large number of iterations.

Additionally, duplicate values are accepted even though
protocol requirements specify that duplicates should be
rejected.

Impact:

An attacker can:

- trigger excessive gas consumption
- create denial-of-service conditions
- bypass business rules requiring unique values
- reduce protocol scalability

If integrated into a larger protocol, oversized inputs
could make functionality expensive or unusable.

Proof of Concept:

1. Deploy contract

2. Attacker calls:

   processNestedArray(
       [
           [1,2,3,...50],
           [51,52,53,...100],
           ...
           hundreds of rows
       ]
   )

3. Contract performs excessive iterations.

OR

4. Attacker calls:

   processNestedArray(
       [
           [1,2],
           [2,3]
       ]
   )

5. Duplicate value "2" is accepted even though
   duplicates should be rejected.

Root Cause:

The function processes user-supplied nested arrays without
performing validation checks on:

- outer array length
- inner array length
- duplicate elements

No safeguards exist to enforce protocol limits.

Recommendation:

Implement strict validation before processing input.

Example:

- Reject outer arrays larger than 50 rows
- Reject inner arrays larger than 50 elements
- Reject duplicate values
- Use custom errors instead of require strings
  for gas efficiency

Example:

if (_numbers.length > 50)
    revert ArrayTooLarge();

if (_numbers[i].length > 50)
    revert ArrayTooLarge();

if (duplicateFound)
    revert DuplicateValue(value);

This ensures predictable gas costs, prevents abuse through
oversized calldata, and enforces protocol business rules.
*/

//Patched code
contract ValidateNestedArrayPatched {

    error ArrayTooLarge();
    error DuplicateValue(uint256 value);

    function processNestedArray(
        uint256[][] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        // Maximum 50 rows
        if (_numbers.length > 50) {
            revert ArrayTooLarge();
        }

        uint256 total;

        for (uint256 i = 0; i < _numbers.length; i++) {

            // Maximum 50 columns
            if (_numbers[i].length > 50) {
                revert ArrayTooLarge();
            }

            for (uint256 j = 0; j < _numbers[i].length; j++) {

                uint256 current =
                    _numbers[i][j];

                // Check duplicates
                for (uint256 x = 0; x < _numbers.length; x++) {

                    for (
                        uint256 y = 0;
                        y < _numbers[x].length;
                        y++
                    ) {

                        if (
                            x == i &&
                            y == j
                        ) {
                            continue;
                        }

                        if (
                            _numbers[x][y] ==
                            current
                        ) {
                            revert DuplicateValue(
                                current
                            );
                        }
                    }
                }

                total += current;
            }
        }

        return total;
    }
}