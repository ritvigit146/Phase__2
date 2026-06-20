// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Use calldata in external function
CONCEPT: External optimization
=========================================================

OBJECTIVE

- Learn why calldata is used in external functions
- Understand gas optimization using calldata
- Learn efficient external input handling
- Understand calldata vs memory behavior

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

External functions receive input data
through calldata.

Using calldata:
- avoids unnecessary copying
- reduces gas cost
- improves efficiency

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

For external functions:

calldata is usually better than memory
for read-only inputs.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Gas optimization is critical in:

- DeFi protocols
- NFT marketplaces
- routers
- multicall systems
- governance contracts

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Calldata heavily used in:

- Uniswap routers
- token batch transfers
- governance voting
- multicall contracts
- staking systems

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata used where appropriate?
- Are unnecessary memory copies created?
- Are loops scalable?
- Can attacker-controlled inputs create DOS?
- Is gas usage optimized?

=========================================================
*/
contract ExternalCalldataOptimizationVul {

    uint256[] public savedNumbers;

    function saveValues(
        uint256[] calldata _numbers
    )
        external
    {
        for (uint256 i = 0; i < _numbers.length; i++) {
            savedNumbers.push(_numbers[i]);
        }
    }

    function calculateSum(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        uint256 total;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function echoMessage(
        string calldata _message
    )
        external
        pure
        returns (string memory)
    {
        return _message;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
calculateSum([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Function reads directly from calldata
3. No memory copy created
4. Loop processes values
5. Result returned
6. Calldata discarded after execution

---------------------------------------------------------

RESULT:
6

---------------------------------------------------------

GAS:
Efficient

=========================================================

CALL:
calculateSumMemory([1,2,3])

EVM ACTIONS:

1. Array copied into memory
2. Memory allocation occurs
3. Loop processes memory array
4. Result returned

---------------------------------------------------------

GAS:
More expensive than calldata version

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
calculateSum([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 3:
Call:
calculateSumMemory([1,2,3])

EXPECTED:
6

---------------------------------------------------------

STEP 4:
Compare gas usage

OBSERVE:
calldata version cheaper

---------------------------------------------------------

STEP 5:
Call:
echoMessage("Blockchain")

EXPECTED:
"Blockchain"

---------------------------------------------------------

STEP 6:
Call:
saveValues([10,20])

---------------------------------------------------------

STEP 7:
Call:
savedNumbers(0)

EXPECTED:
10

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Pass empty array

EXPECTED:
0

---------------------------------------------------------

TEST:
Pass huge array

OBSERVE:
Higher gas consumption

---------------------------------------------------------

TEST:
Pass large string

OBSERVE:
Dynamic calldata still costs gas

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA:
- temporary
- read-only
- external-input optimized

---------------------------------------------------------

BEST USED FOR:
Read-only external parameters.

=========================================================
WHY EXTERNAL + CALLDATA IS OPTIMAL
=========================================================

EXTERNAL FUNCTION:
Reads directly from calldata.

---------------------------------------------------------

NO MEMORY COPY NEEDED.

---------------------------------------------------------

RESULT:
Lower gas usage.

=========================================================
CALLDATA RESTRICTION
=========================================================

CALLDATA CANNOT BE MODIFIED.

---------------------------------------------------------

THIS FAILS:

_numbers[0] = 999;

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
CALLDATA VS MEMORY
=========================================================

---------------------------------------------------------
CALLDATA
---------------------------------------------------------

Read-only

Cheaper

No copying

Best for external input

---------------------------------------------------------
MEMORY
---------------------------------------------------------

Mutable

Requires allocation

More expensive

Useful for modifications

=========================================================
GAS OBSERVATION
=========================================================

CALLDATA:
Lower gas usage

---------------------------------------------------------

MEMORY:
Higher gas usage due to:
- copying
- allocation
- expansion

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. GAS OPTIMIZATION
---------------------------------------------------------

Auditors check:
whether calldata can replace memory.

---------------------------------------------------------
2. DOS VIA LARGE ARRAYS
---------------------------------------------------------

Huge attacker-controlled arrays
may exhaust gas.

---------------------------------------------------------
3. UNBOUNDED LOOPS
---------------------------------------------------------

Loops over calldata arrays
must be bounded safely.

---------------------------------------------------------
4. MUTABILITY CONFUSION
---------------------------------------------------------

Developers must understand:
calldata is immutable.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits massive calldata array.

Loop processing becomes too expensive.

Result:
- DOS condition
- transaction failure

---------------------------------------------------------

ANOTHER RISK

Developer unnecessarily copies:
calldata -> memory

Result:
wasted gas and poor scalability.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata string array
2. Count total characters
3. Add max input limit

BONUS:
Measure gas:
calldata vs memory for large arrays

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External functions naturally use calldata
- Calldata is gas efficient
- Calldata avoids memory copying
- Calldata is read-only
- Memory is mutable but expensive
- Large arrays increase gas usage
- Unbounded loops create DOS risks
- Gas optimization matters heavily
- External input is attacker-controlled
- Auditors inspect calldata efficiency carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in saveValues()

Severity: Medium because unauthorized users can
modify permanent contract storage.

Location: Contract: ExternalCalldataOptimizationVul
Function: saveValues()

Vulnerability Description:

The saveValues() function allows any external user
to append arbitrary values into the savedNumbers
storage array because no access control mechanism
is implemented.

Impact:

An attacker can insert arbitrary values into storage.

If this array controlled critical protocol logic such as:

- governance participant lists
- reward calculations
- staking records
- protocol configuration

then unauthorized users could manipulate
system behavior.

Proof of Concept:

1. Deploy contract

2. User A calls:
   saveValues([10,20])

3. Attacker calls:
   saveValues([999,888,777])

4. Contract storage is modified successfully

5. savedNumbers now contains attacker-controlled data

Root Cause:

The function is declared external without
any authorization checks.

No require() statement validates the caller identity.

Recommendation:

Restrict access using an owner check.

Example:

require(msg.sender == owner, "Not owner");
*/

//Patched code
contract ExternalCalldataOptimizationPatched {

    address public owner;

    uint256[] public savedNumbers;

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

    function saveValues(
        uint256[] calldata _numbers
    )
        external
        onlyOwner
    {
        require(
            _numbers.length <= 100,
            "Array too large"
        );

        for (uint256 i = 0; i < _numbers.length; i++) {
            savedNumbers.push(_numbers[i]);
        }
    }

    function calculateSum(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256)
    {
        uint256 total;

        for (uint256 i = 0; i < _numbers.length; i++) {
            total += _numbers[i];
        }

        return total;
    }

    function echoMessage(
        string calldata _message
    )
        external
        pure
        returns (string memory)
    {
        return _message;
    }
}