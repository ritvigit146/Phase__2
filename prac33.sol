// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Return calldata value
CONCEPT: Read-only flow
=========================================================

OBJECTIVE

- Learn how calldata values are returned
- Understand read-only calldata flow
- Learn external input lifecycle
- Understand calldata efficiency

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

External input arrives in calldata.

Contract can:
- read calldata
- process calldata
- return calldata data

BUT:
cannot modify calldata directly.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Calldata is:
- temporary
- immutable
- external-input optimized

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most smart contract interactions:
- receive calldata
- process calldata
- return derived values

Understanding this flow is critical for:
- auditing
- gas optimization
- ABI understanding

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Returning calldata-derived data used in:

- routers
- multicall systems
- APIs
- governance queries
- DeFi calculations

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- Is calldata copied unnecessarily?
- Is input trusted incorrectly?
- Are dynamic types handled safely?
- Are large returns scalable?
- Is gas optimized?

=========================================================
*/

contract ReturnCalldataValue {

    /*
        STORAGE VARIABLE

        Permanent blockchain state.
    */
    string public savedMessage;

    /*
    =====================================================
    RETURN UINT FROM CALLDATA
    =====================================================
    */

    function returnUint(
        uint256 _number
    )
        external
        pure
        returns (uint256)
    {

        /*
            _number arrives through calldata.

            Function simply returns it.
        */
        return _number;
    }

    /*
    =====================================================
    RETURN STRING FROM CALLDATA
    =====================================================
    */

    function returnMessage(
        string calldata _message
    )
        external
        pure
        returns (string memory)
    {

        /*
            _message exists in calldata.

            Returned as memory value.
        */
        return _message;
    }

    /*
    =====================================================
    RETURN ARRAY FROM CALLDATA
    =====================================================
    */

    function returnArray(
        uint256[] calldata _numbers
    )
        external
        pure
        returns (uint256[] memory)
    {

        /*
            Returning calldata-derived array.

            Solidity ABI-encodes return data.
        */
        return _numbers;
    }

    /*
    =====================================================
    STORE CALLDATA VALUE
    =====================================================
    */

    function saveMessage(
        string calldata _message
    )
        external
    {

        /*
            Copy calldata into storage.
        */
        savedMessage = _message;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

CALL:
returnUint(50)

EVM ACTIONS:

1. External input encoded into calldata
2. _number read directly
3. Value returned
4. Calldata discarded after execution

---------------------------------------------------------

RESULT:
50

=========================================================

CALL:
returnMessage("Hello")

EVM ACTIONS:

1. String stored in calldata
2. Function reads calldata
3. Return data ABI-encoded
4. Memory used for returned value
5. Calldata discarded

---------------------------------------------------------

RESULT:
"Hello"

=========================================================

CALL:
returnArray([1,2,3])

EVM ACTIONS:

1. Array arrives in calldata
2. Array read directly
3. ABI encoding prepares return data
4. Returned to caller
5. Temporary data cleared

---------------------------------------------------------

RESULT:
[1,2,3]

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
returnUint(123)

EXPECTED:
123

---------------------------------------------------------

STEP 3:
Call:
returnMessage("Solidity")

EXPECTED:
"Solidity"

---------------------------------------------------------

STEP 4:
Call:
returnArray([10,20,30])

EXPECTED:
[10,20,30]

---------------------------------------------------------

STEP 5:
Call:
saveMessage("Blockchain")

---------------------------------------------------------

STEP 6:
Call:
savedMessage()

EXPECTED:
"Blockchain"

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Return empty string

EXPECTED:
""

---------------------------------------------------------

TEST:
Return empty array

EXPECTED:
[]

---------------------------------------------------------

TEST:
Return very large array

OBSERVE:
Higher gas usage for encoding

=========================================================
IMPORTANT CALLDATA UNDERSTANDING
=========================================================

CALLDATA:
- temporary
- read-only
- optimized for external input

---------------------------------------------------------

CALLDATA EXISTS ONLY:
during execution.

---------------------------------------------------------

AFTER FUNCTION ENDS:
Calldata disappears automatically.

=========================================================
WHY RETURN TYPES USE MEMORY
=========================================================

NOTICE:

returns (string memory)

---------------------------------------------------------

WHY?

Returned dynamic data must be:
ABI-encoded into memory.

---------------------------------------------------------

Dynamic return values use memory.

=========================================================
READ-ONLY FLOW
=========================================================

FLOW:

External Caller
    ->
Calldata Input
    ->
Contract Reads Data
    ->
Return Value Generated
    ->
Execution Ends

---------------------------------------------------------

IMPORTANT:
Original calldata never changes.

=========================================================
CALLDATA IMMUTABILITY
=========================================================

THIS FAILS:

_message = "Hack";

---------------------------------------------------------

Reason:
calldata is immutable.

=========================================================
GAS OBSERVATION
=========================================================

READING CALLDATA:
Cheap

---------------------------------------------------------

RETURNING LARGE DATA:
Expensive

---------------------------------------------------------

Reason:
ABI encoding costs gas.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. INPUT VALIDATION
---------------------------------------------------------

All calldata inputs are attacker-controlled.

Never trust external input.

---------------------------------------------------------
2. LARGE RETURN DATA
---------------------------------------------------------

Huge arrays/strings may:
- consume excessive gas
- create scalability problems

---------------------------------------------------------
3. UNNECESSARY COPYING
---------------------------------------------------------

Auditors check:
whether calldata is copied inefficiently.

---------------------------------------------------------
4. ABI ENCODING COSTS
---------------------------------------------------------

Returning large dynamic data
can become expensive.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Attacker submits huge calldata array.

Contract returns massive response.

Result:
- excessive gas
- DOS conditions
- unusable functions

---------------------------------------------------------

ANOTHER RISK

Developer assumes calldata mutable.

Logic behaves incorrectly.

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Accept calldata uint array
2. Return reversed array
3. Use memory safely for modifications

BONUS:
Compare gas for:
small vs large returned arrays

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Calldata stores external input
- Calldata is read-only
- Calldata is temporary
- External functions read calldata efficiently
- Dynamic return values use memory
- ABI encoding powers return values
- Large return data increases gas
- External input is attacker-controlled
- Returning calldata-derived data is common
- Auditors inspect data flow carefully

=========================================================
*/