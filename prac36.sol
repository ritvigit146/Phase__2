// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Execute function line-by-line manually
CONCEPT: Mental execution tracing
=========================================================

OBJECTIVE

- Learn how to mentally execute Solidity code
- Understand EVM execution flow
- Learn state changes step-by-step
- Build auditor-style tracing skills

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Professional auditors mentally trace:

- every variable change
- every storage update
- every require()
- every loop iteration
- every external call

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Auditing is NOT only reading syntax.

You must simulate execution in your head.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most vulnerabilities are found by:

- tracing state changes
- understanding execution order
- detecting unexpected behavior

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Mental execution tracing is critical for:

- smart contract auditing
- exploit analysis
- protocol reviews
- gas optimization
- invariant checking

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors mentally track:

- msg.sender
- msg.value
- storage changes
- memory usage
- require conditions
- external interactions
- reentrancy possibilities

=========================================================
*/
contract MentalExecutionTracingVul {

    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    function deposit(
        uint256 _amount
    )
        external
    {
        require(
            _amount > 0,
            "Invalid amount"
        );

        balances[msg.sender] =
            balances[msg.sender] + _amount;

        totalBalance =
            totalBalance + _amount;
    }

    function withdraw(
        uint256 _amount
    )
        external
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        balances[msg.sender] =
            balances[msg.sender] - _amount;

        totalBalance =
            totalBalance - _amount;
    }
}

/*
=========================================================
MANUAL EXECUTION TRACE
=========================================================

---------------------------------------------------------
INITIAL STATE
---------------------------------------------------------

totalBalance = 0

balances[Alice] = 0

=========================================================
TRACE:
deposit(100)
called by Alice
=========================================================

---------------------------------------------------------
STEP 1
---------------------------------------------------------

require(_amount > 0)

CHECK:
100 > 0

RESULT:
true

Execution continues.

---------------------------------------------------------
STEP 2
---------------------------------------------------------

currentBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 0

SO:

currentBalance = 0

---------------------------------------------------------
STEP 3
---------------------------------------------------------

newBalance =
currentBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = newBalance

STORAGE UPDATE:

balances[Alice] = 100

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
totalBalance + _amount

= 0 + 100

= 100

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 100

totalBalance = 100

=========================================================
SECOND TRACE
=========================================================

CALL:
withdraw(40)

by Alice

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance =
balances[Alice]

READ STORAGE:

balances[Alice] = 100

---------------------------------------------------------
STEP 2
---------------------------------------------------------

require(userBalance >= _amount)

CHECK:
100 >= 40

RESULT:
true

---------------------------------------------------------
STEP 3
---------------------------------------------------------

updatedBalance =
100 - 40

= 60

---------------------------------------------------------
STEP 4
---------------------------------------------------------

balances[Alice] = 60

STORAGE UPDATED

---------------------------------------------------------
STEP 5
---------------------------------------------------------

totalBalance =
100 - 40

= 60

---------------------------------------------------------
FINAL STATE
---------------------------------------------------------

balances[Alice] = 60

totalBalance = 60

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy contract

---------------------------------------------------------

STEP 2:
Call:
deposit(100)

---------------------------------------------------------

STEP 3:
Call:
balances(your_address)

EXPECTED:
100

---------------------------------------------------------

STEP 4:
Call:
totalBalance()

EXPECTED:
100

---------------------------------------------------------

STEP 5:
Call:
withdraw(40)

---------------------------------------------------------

STEP 6:
Call:
balances(your_address)

EXPECTED:
60

---------------------------------------------------------

STEP 7:
Call:
totalBalance()

EXPECTED:
60

=========================================================
FAILURE TRACE
=========================================================

CALL:
withdraw(1000)

WHEN:
balance = 60

---------------------------------------------------------
STEP 1
---------------------------------------------------------

userBalance = 60

---------------------------------------------------------
STEP 2
---------------------------------------------------------

CHECK:
60 >= 1000

RESULT:
false

---------------------------------------------------------
TRANSACTION REVERTS
---------------------------------------------------------

NO STATE CHANGES OCCUR.

=========================================================
IMPORTANT AUDITOR SKILL
=========================================================

WHILE TRACING:

Track:

- storage reads
- storage writes
- memory variables
- require conditions
- execution order
- state before/after

=========================================================
WHY EXECUTION ORDER MATTERS
=========================================================

Incorrect order may cause:

- reentrancy
- stale state
- accounting bugs
- invariant violations

=========================================================
MENTAL MODEL USED BY AUDITORS
=========================================================

FOR EVERY LINE ASK:

1. What data is read?
2. From storage/memory/calldata?
3. What changes?
4. Can execution revert?
5. What happens if attacker controls input?
6. What is final state?

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

---------------------------------------------------------
1. TRACE STATE CAREFULLY
---------------------------------------------------------

Most bugs hide in:
state transitions.

---------------------------------------------------------
2. WATCH STORAGE WRITES
---------------------------------------------------------

Storage changes are critical.

---------------------------------------------------------
3. CHECK REQUIRE ORDER
---------------------------------------------------------

Validation must happen before:
dangerous operations.

---------------------------------------------------------
4. THINK LIKE ATTACKER
---------------------------------------------------------

Ask:
"What if input is malicious?"

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

If require() were missing:

Attacker could:
withdraw more than balance.

---------------------------------------------------------

ANOTHER RISK

Incorrect execution order may:
enable reentrancy exploits.

=========================================================
MINI CHALLENGE
=========================================================

Manually trace:

1. deposit(500)
2. withdraw(200)
3. deposit(50)

Write:
- every variable value
- every storage update
- final contract state

BONUS:
Add transfer() function
and trace sender + receiver balances.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Auditors mentally execute code
- Storage changes must be tracked carefully
- require() controls execution flow
- Reverts undo state changes
- Execution order matters heavily
- State tracing reveals vulnerabilities
- External input is attacker-controlled
- Storage/memory/calldata differ greatly
- Manual tracing is essential for auditing
- Professional auditors simulate EVM execution mentally

=========================================================
*/
/*
Audit Report

Title: Improper Accounting Due to User-Controlled Deposit Amount

Severity: Medium because users can create arbitrary balances
without depositing real assets into the contract.

Location:
Contract: MentalExecutionTracing
Function: deposit()

Vulnerability Description:

The deposit() function accepts a user-controlled _amount
parameter and credits the caller's balance using that value.

The contract assumes that the supplied amount represents a
real deposit, but no ETH transfer or asset transfer occurs.

As a result, any user can increase their recorded balance
and the global totalBalance by providing an arbitrary number.

Impact:

An attacker can:

- create fake balances
- inflate totalBalance
- manipulate protocol accounting
- bypass intended deposit requirements

If future functionality relies on these balances for
withdrawals, rewards, voting power, or access control,
the attacker may gain unfair advantages.

Proof of Concept:

1. Deploy contract

2. Attacker calls:

   deposit(1000000)

3. Execution:

   balances[attacker] = 1000000
   totalBalance = 1000000

4. No ETH or tokens were transferred to the contract.

5. The attacker now possesses a large recorded balance
   without providing any value.

Root Cause:

The function trusts a user-supplied _amount parameter.

The contract updates accounting state based solely on
external input and does not verify that any assets were
actually received.

Recommendation:

Use actual transferred value instead of trusting user input.

For ETH deposits:

   function deposit()
       external
       payable
   {
       require(
           msg.value > 0,
           "No ETH sent"
       );

       balances[msg.sender] += msg.value;
       totalBalance += msg.value;
   }

For ERC20 deposits:

- Transfer tokens into the contract
- Verify transfer success
- Credit balances based on actual tokens received

This ensures contract accounting matches real asset balances.
*/
//Patched code
contract MentalExecutionTracingPatched {

    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    function deposit()
        external
        payable
    {
        require(
            msg.value > 0,
            "No ETH sent"
        );

        balances[msg.sender] += msg.value;

        totalBalance += msg.value;
    }

    function withdraw(
        uint256 _amount
    )
        external
    {
        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        balances[msg.sender] -= _amount;

        totalBalance -= _amount;

        payable(msg.sender).transfer(_amount);
    }
}