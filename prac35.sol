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

contract ValidateCalldataInput {

    /*
        STATE VARIABLES

        Permanent blockchain state.
    */
    uint256 public storedAmount;

    address public lastReceiver;

    /*
    =====================================================
    VALIDATE UINT INPUT
    =====================================================
    */

    function deposit(
        uint256 _amount
    )
        external
    {

        /*
            VALIDATION:
            Amount must be greater than zero.
        */
        require(
            _amount > 0,
            "Amount must be > 0"
        );

        /*
            VALIDATION:
            Prevent excessively large deposits.
        */
        require(
            _amount <= 1000 ether,
            "Amount too large"
        );

        /*
            Store validated value.
        */
        storedAmount = _amount;
    }

    /*
    =====================================================
    VALIDATE ADDRESS INPUT
    =====================================================
    */

    function setReceiver(
        address _receiver
    )
        external
    {

        /*
            VALIDATION:
            Prevent zero address.
        */
        require(
            _receiver != address(0),
            "Invalid address"
        );

        lastReceiver = _receiver;
    }

    /*
    =====================================================
    VALIDATE ARRAY INPUT
    =====================================================
    */

    function processArray(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {

        /*
            VALIDATION:
            Prevent huge arrays.
        */
        require(
            _numbers.length <= 100,
            "Array too large"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _numbers.length; i++) {

            /*
                VALIDATION:
                Reject zero values.
            */
            require(
                _numbers[i] > 0,
                "Invalid number"
            );

            total += _numbers[i];
        }

        return total;
    }

    /*
    =====================================================
    VALIDATE STRING INPUT
    =====================================================
    */

    function validateMessage(
        string calldata _message
    )
        external
        pure
        returns (bool)
    {

        /*
            Convert string to bytes
            to check length.
        */
        bytes calldata messageBytes =
            bytes(_message);

        /*
            VALIDATION:
            Reject empty strings.
        */
        require(
            messageBytes.length > 0,
            "Empty message"
        );

        /*
            VALIDATION:
            Prevent excessively large input.
        */
        require(
            messageBytes.length <= 50,
            "Message too long"
        );

        return true;
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

Title: No Security Vulnerabilities Identified

Severity: Informational

Location: Contract: ValidateCalldataInput

Summary:

The contract demonstrates proper calldata input validation techniques and does not contain any obvious security vulnerabilities within the provided scope.

Review Findings:

1. Numeric Input Validation

The deposit() function validates:

* Amount is greater than zero
* Amount does not exceed the defined maximum limit

Example:

require(_amount > 0, "Amount must be > 0");
require(_amount <= 1000 ether, "Amount too large");

Result:
Invalid numeric inputs are rejected.

---

2. Address Validation

The setReceiver() function validates:

* Receiver is not the zero address

Example:

require(
_receiver != address(0),
"Invalid address"
);

Result:
Prevents accidental use of the zero address.

---

3. Array Validation

The processArray() function validates:

* Maximum array length
* Individual element values

Examples:

require(
_numbers.length <= 100,
"Array too large"
);

require(
_numbers[i] > 0,
"Invalid number"
);

Result:
Mitigates gas-exhaustion risks and invalid input values.

---

4. String Validation

The validateMessage() function validates:

* Non-empty strings
* Maximum string length

Examples:

require(
messageBytes.length > 0,
"Empty message"
);

require(
messageBytes.length <= 50,
"Message too long"
);

Result:
Prevents empty and excessively large string inputs.

---

Security Assessment

The contract correctly treats all external calldata as untrusted input and performs validation before processing.

No instances of:

* Missing input validation
* Unbounded array processing
* Zero-address misuse
* Integer overflow
* Reentrancy
* Unsafe external calls

were identified.

Conclusion:

No security vulnerabilities were identified during review.

The contract serves as a secure example of manual calldata validation and follows recommended Solidity input-validation practices.
*/