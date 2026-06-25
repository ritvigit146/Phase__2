// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Trigger fallback during call
CONCEPT: External execution
=========================================================

OBJECTIVE

- Learn how fallback() gets triggered
- Understand low-level external execution
- Learn unknown-function behavior
- Understand fallback attack surface

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

fallback() executes when:

1. unknown function called
OR
2. calldata does not match any function

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

fallback() is external execution.

---------------------------------------------------------

Control jumps into:
another contract unexpectedly.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

fallback() is heavily used in:

- proxies
- routers
- upgradeable contracts
- ETH receivers
- attack contracts
- low-level interactions

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Fallback logic appears in:

- proxy delegation
- DeFi routing
- reentrancy attacks
- ETH receiving
- upgrade patterns

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- fallback execution paths
- hidden external calls
- reentrancy behavior
- delegatecall risks
- gas usage

=========================================================
TARGET CONTRACT
=========================================================
*/
contract TargetContractVul {

    uint256 public fallbackCounter;
    uint256 public receivedETH;

    /*
        VULNERABLE:
        Any unknown function call
        executes fallback logic.
    */
    fallback()
        external
        payable
    {
        fallbackCounter++;

        receivedETH += msg.value;
    }

    receive()
        external
        payable
    {
        receivedETH += msg.value;
    }

    function normalFunction()
        external
        pure
        returns (string memory)
    {
        return "Normal execution";
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy TargetContract

---------------------------------------------------------

STEP 2:
Deploy FallbackCaller

Constructor input:
TargetContract address

=========================================================
TRACE:
triggerFallback()
=========================================================

STEP 1:
Caller contract executes.

---------------------------------------------------------

STEP 2:
Low-level call created:

target.call(
    abi.encodeWithSignature(
        "doesNotExist()"
    )
)

---------------------------------------------------------

STEP 3:
Execution jumps into:
TargetContract

---------------------------------------------------------

EVM searches for:

doesNotExist()

---------------------------------------------------------

RESULT:
Function NOT FOUND

---------------------------------------------------------

STEP 4:
fallback() automatically executes.

=========================================================
INSIDE fallback()
=========================================================

fallbackCounter++

---------------------------------------------------------

NEW VALUE:
1

---------------------------------------------------------

receivedETH += msg.value

msg.value = 0

=========================================================
IMPORTANT FALLBACK UNDERSTANDING
=========================================================

fallback() executes when:
no matching function exists.

=========================================================
ETH + FALLBACK TRACE
=========================================================

CALL:
triggerFallbackWithETH()

VALUE:
1 ETH

=========================================================

STEP 1:
ETH + invalid calldata sent.

---------------------------------------------------------

STEP 2:
No matching function found.

---------------------------------------------------------

STEP 3:
fallback() executes.

---------------------------------------------------------

fallbackCounter++

---------------------------------------------------------

receivedETH += 1 ETH

=========================================================
RECEIVE TRACE
=========================================================

CALL:
triggerReceive()

VALUE:
1 ETH

=========================================================

STEP 1:
ETH sent with EMPTY calldata.

---------------------------------------------------------

STEP 2:
receive() executes.

---------------------------------------------------------

receivedETH += 1 ETH

=========================================================
IMPORTANT DIFFERENCE
=========================================================

---------------------------------------------------------
receive()
---------------------------------------------------------

Triggered when:
- ETH sent
- calldata EMPTY

---------------------------------------------------------
fallback()
---------------------------------------------------------

Triggered when:
- unknown function called
- calldata unmatched

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy TargetContract

---------------------------------------------------------

STEP 2:
Deploy FallbackCaller

Input:
TargetContract address

---------------------------------------------------------

STEP 3:
Call:
triggerFallback()

---------------------------------------------------------

STEP 4:
Open TargetContract

---------------------------------------------------------

STEP 5:
Call:
fallbackCounter()

EXPECTED:
1

---------------------------------------------------------

STEP 6:
In VALUE field:
enter 1 ether

---------------------------------------------------------

STEP 7:
Call:
triggerFallbackWithETH()

---------------------------------------------------------

STEP 8:
Call:
receivedETH()

EXPECTED:
1 ETH in wei

---------------------------------------------------------

STEP 9:
Call:
triggerReceive()

with 1 ETH

---------------------------------------------------------

STEP 10:
Call:
receivedETH()

EXPECTED:
2 ETH total

=========================================================
IMPORTANT SECURITY UNDERSTANDING
=========================================================

fallback() enables:
unexpected external execution.

---------------------------------------------------------

Huge attack surface.

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

fallback() may reenter vulnerable contract.

---------------------------------------------------------
2. PROXY RISKS
---------------------------------------------------------

fallback() commonly delegates execution.

---------------------------------------------------------
3. UNEXPECTED EXECUTION
---------------------------------------------------------

Unknown calls may trigger hidden logic.

---------------------------------------------------------
4. GAS DOS
---------------------------------------------------------

Complex fallback may exhaust gas.

=========================================================
VERY IMPORTANT ATTACK CONCEPT
=========================================================

Malicious contracts often attack using:

fallback()/receive()

---------------------------------------------------------

Because:
they trigger automatically during ETH transfer.

=========================================================
LOW-LEVEL CALL UNDERSTANDING
=========================================================

call() bypasses:
compile-time function checks.

---------------------------------------------------------

Meaning:
ANY calldata possible.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Can fallback trigger unexpectedly?
- Can fallback reenter?
- Does fallback delegatecall?
- Is fallback payable?
- Are unknown calls handled safely?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Victim contract sends ETH.

---------------------------------------------------------

Attacker fallback executes automatically.

---------------------------------------------------------

Fallback reenters victim contract.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. External call flow
2. Fallback trigger conditions
3. Reentrancy windows
4. ETH transfer behavior
5. Unknown calldata handling

=========================================================
MINI CHALLENGE
=========================================================

Modify contracts so that:

1. Add event inside fallback()
2. Add reentrant fallback attack
3. Add nonReentrant protection
4. Compare receive vs fallback execution

BONUS:
Build mini proxy fallback contract.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- fallback() handles unknown function calls
- receive() handles plain ETH transfers
- Low-level call() can trigger fallback
- fallback() creates external execution flow
- fallback() is major attack surface
- Reentrancy often uses fallback()
- call() bypasses compile-time safety
- Unknown calldata may trigger hidden logic
- Auditors inspect fallback paths carefully
- External execution is critical in Solidity security

=========================================================
*/
/*
Audit Report

Title: Unrestricted Fallback Execution Through Low-Level Calls

Severity: Medium because arbitrary users can trigger
fallback execution and modify contract state through
unknown function calls.

Location:
Contract: TargetContract
Function: fallback()

Vulnerability Description:

The fallback() function is payable and executes whenever
a call is received with an unknown function selector.

Any external user can invoke fallback() by sending
arbitrary calldata through a low-level call.

Since no validation, filtering, or access control exists,
unexpected execution paths are possible.

Although the current implementation only updates counters,
fallback functions are common attack surfaces and may
become dangerous if additional business logic is added.

Impact:

An attacker can repeatedly trigger fallback execution.

Potential consequences include:

- unexpected state modifications
- abuse of hidden execution paths
- increased attack surface
- denial of service through excessive calls
- future security risks if fallback logic expands

Proof of Concept:

1. Deploy TargetContract

2. Execute:

   target.call(
       abi.encodeWithSignature(
           "doesNotExist()"
       )
   );

3. Function selector does not exist

4. EVM automatically executes:

   fallback()

5. Contract state changes:

   fallbackCounter++

6. Attacker can repeatedly invoke unknown
   functions to trigger fallback execution

Root Cause:

The fallback() function accepts arbitrary unknown calls
without validation.

Vulnerable code:

    fallback()
        external
        payable
    {
        fallbackCounter++;

        receivedETH += msg.value;
    }

Recommendation:

Reject unexpected function calls unless fallback behavior
is explicitly required.

Example:

    fallback()
        external
        payable
    {
        revert("Unknown function");
    }

If fallback functionality is necessary, implement
strict validation and access controls before executing
state-changing logic.

Status:

Fixed in patched implementation.

*/

// Patched code
contract TargetContract {

    uint256 public fallbackCounter;
    uint256 public receivedETH;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /*
        PATCH:
        Reject unknown function calls.
    */
    fallback()
        external
        payable
    {
        revert("Unknown function");
    }

    receive()
        external
        payable
    {
        receivedETH += msg.value;
    }

    function normalFunction()
        external
        pure
        returns (string memory)
    {
        return "Normal execution";
    }
}