// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Pass nested calldata array
CONCEPT: Complex input handling
=========================================================

OBJECTIVE

- Learn how nested calldata arrays work
- Understand complex ABI input decoding
- Learn handling of multi-dimensional arrays
- Understand gas/scaling risks of nested structures

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Nested arrays are arrays inside arrays.

Example:

[
    [1,2],
    [3,4],
    [5,6]
]

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Nested calldata arrays:
- are read-only
- are externally supplied
- require ABI decoding
- can become expensive at scale

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Complex nested structures appear in:

- batch DeFi operations
- governance systems
- Merkle proofs
- routing paths
- advanced multicalls

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Nested arrays used in:

- Uniswap swap paths
- batch execution systems
- matrix-style computations
- grouped transactions
- multi-user operations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Input complexity
- Nested loop gas risks
- ABI decoding correctness
- DOS vulnerabilities
- Scalability failures

=========================================================
*/
contract NestedCalldataArrayVul {

    uint256 public totalSum;

    function processAndStore(
        uint256[][] calldata _matrix
    )
        external
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _matrix.length; i++) {
            for (uint256 j = 0; j < _matrix[i].length; j++) {
                total += _matrix[i][j];
            }
        }

        // VULNERABILITY:
        // Any user can overwrite protocol state.
        totalSum = total;
    }

    function calculateNestedSum(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _matrix.length; i++) {
            for (uint256 j = 0; j < _matrix[i].length; j++) {
                total += _matrix[i][j];
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

calculateNestedSum(
[
    [1,2],
    [3,4]
]
)

=========================================================

EVM ACTIONS

1. Nested array arrives in calldata
2. Solidity ABI-decodes structure
3. Outer loop processes rows
4. Inner loop processes elements
5. Total computed
6. Result returned
7. Calldata discarded

---------------------------------------------------------

CALCULATION:

1 + 2 + 3 + 4 = 10

---------------------------------------------------------

RESULT:
10

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
readNestedArray()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
Same nested array returned

---------------------------------------------------------

STEP 3:
Call:
calculateNestedSum()

INPUT:

[
    [1,2],
    [3,4]
]

EXPECTED:
10

---------------------------------------------------------

STEP 4:
Call:
processAndStore()

INPUT:

[
    [5,5],
    [10]
]

---------------------------------------------------------

STEP 5:
Call:
totalSum()

EXPECTED:
20

---------------------------------------------------------

STEP 6:
Call:
getOuterLength()

INPUT:

[
    [1],
    [2],
    [3]
]

EXPECTED:
3

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Empty outer array

INPUT:
[]

EXPECTED:
0

---------------------------------------------------------

TEST:
Empty inner arrays

INPUT:
[
    [],
    []
]

EXPECTED:
0

---------------------------------------------------------

TEST:
Very large nested arrays

OBSERVE:
Extremely high gas usage

=========================================================
IMPORTANT NESTED ARRAY UNDERSTANDING
=========================================================

TYPE:

uint256[][] calldata

---------------------------------------------------------

MEANS:

Array of uint256 arrays.

---------------------------------------------------------

STRUCTURE:

[
    [row1],
    [row2],
    [row3]
]

=========================================================
NESTED LOOP RISK
=========================================================

THIS IS IMPORTANT:

Nested loops scale badly.

---------------------------------------------------------

OUTER LOOP:
N iterations

INNER LOOP:
M iterations

---------------------------------------------------------

TOTAL OPERATIONS:
N × M

=========================================================
CALLDATA IMMUTABILITY
=========================================================

Nested calldata arrays are:
READ-ONLY.

---------------------------------------------------------

THIS FAILS:

_matrix[0][0] = 999;

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
ABI DECODING COMPLEXITY
=========================================================

Nested arrays require:
complex ABI decoding.

---------------------------------------------------------

LARGER STRUCTURES:
More decoding cost.

=========================================================
GAS OBSERVATION
=========================================================

SMALL NESTED ARRAYS:
Cheap

---------------------------------------------------------

LARGE NESTED ARRAYS:
Very expensive

---------------------------------------------------------

NESTED LOOPS:
Multiply gas consumption rapidly

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. DOS VIA NESTED LOOPS
---------------------------------------------------------

Most important risk.

Nested attacker-controlled arrays
can exhaust gas quickly.

---------------------------------------------------------
2. UNBOUNDED INPUTS
---------------------------------------------------------

Large nested structures may:
- exceed block gas limit
- break protocol usability

---------------------------------------------------------
3. ABI DECODING RISKS
---------------------------------------------------------

Complex nested structures
increase decoding complexity.

---------------------------------------------------------
4. SCALABILITY FAILURES
---------------------------------------------------------

Functions may become unusable
as input size grows.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge nested arrays.

Nested loops explode computational cost.

Result:
- out-of-gas
- DOS condition
- protocol unusability

---------------------------------------------------------

REAL-WORLD ISSUE

Improper batch-processing logic
has caused scalability failures
in production contracts.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Find largest number
inside nested array

2. Reject arrays larger than:
- outer length > 50
- inner length > 50

BONUS:
Add pagination support.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Nested arrays contain arrays inside arrays
- Nested calldata arrays are read-only
- ABI decoding handles complex structures
- Nested loops scale poorly
- Large nested inputs increase gas heavily
- Unbounded loops create DOS risks
- External inputs are attacker-controlled
- Scalability is critical in Solidity
- Complex structures require careful auditing
- Auditors inspect nested-loop behavior carefully

=========================================================
*/
/*
Audit Report

Title: Missing Access Control in processAndStore()

Severity: Medium because unauthorized users can modify
protocol state.

Location: Contract: NestedCalldataArrayVul
Function: processAndStore()

Vulnerability Description:

The processAndStore() function allows any external user
to modify the totalSum state variable because no access
control mechanism is implemented.

An attacker can supply arbitrary nested arrays and
overwrite the stored value with attacker-controlled data.

Impact:

An attacker can overwrite totalSum with arbitrary values.

If this variable controlled critical protocol logic such as:

- reward calculations
- treasury accounting
- protocol parameters
- governance metrics

then unauthorized users could manipulate
system behavior.

Proof of Concept:

1. Deploy contract

2. User A calls:

   processAndStore(
       [
           [10,20],
           [30]
       ]
   )

3. Contract calculates:

   totalSum = 60

4. Attacker calls:

   processAndStore(
       [
           [999999]
       ]
   )

5. Contract calculates:

   totalSum = 999999

6. Contract state changes successfully

Root Cause:

The function is declared external without any
authorization checks.

No require() statement validates the caller identity
before modifying permanent storage.

Vulnerable Code:

function processAndStore(
    uint256[][] calldata _matrix
)
    external
{
    uint256 total = 0;

    for (uint256 i = 0; i < _matrix.length; i++) {
        for (
            uint256 j = 0;
            j < _matrix[i].length;
            j++
        ) {
            total += _matrix[i][j];
        }
    }

    totalSum = total;
}

Recommendation:

Restrict access using an owner check.

Example:

address public owner;

modifier onlyOwner() {
    require(
        msg.sender == owner,
        "Not owner"
    );
    _;
}

function processAndStore(
    uint256[][] calldata _matrix
)
    external
    onlyOwner
{
    ...
}

Additionally, consider enforcing maximum
row and column limits to mitigate excessive
gas consumption from large nested arrays.

*/

//Patched code
contract NestedCalldataArrayPatched {

    address public owner;
    uint256 public totalSum;

    uint256 public constant MAX_ROWS = 50;
    uint256 public constant MAX_COLUMNS = 50;

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

    function processAndStore(
        uint256[][] calldata _matrix
    )
        external
        onlyOwner
    {
        require(
            _matrix.length <= MAX_ROWS,
            "Too many rows"
        );

        uint256 total = 0;

        for (uint256 i = 0; i < _matrix.length; i++) {

            require(
                _matrix[i].length <= MAX_COLUMNS,
                "Row too large"
            );

            for (uint256 j = 0; j < _matrix[i].length; j++) {
                total += _matrix[i][j];
            }
        }

        totalSum = total;
    }

    function calculateNestedSum(
        uint256[][] calldata _matrix
    )
        external
        pure
        returns (uint256)
    {
        uint256 total = 0;

        for (uint256 i = 0; i < _matrix.length; i++) {
            for (uint256 j = 0; j < _matrix[i].length; j++) {
                total += _matrix[i][j];
            }
        }

        return total;
    }
}