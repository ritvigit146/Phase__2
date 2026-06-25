// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Call another contract
CONCEPT: Inter-contract communication
=========================================================

OBJECTIVE

- Learn how contracts call other contracts
- Understand inter-contract execution flow
- Learn external call behavior
- Understand cross-contract risks

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Smart contracts can:
call functions in other contracts.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

Cross-contract calls create:
NEW execution context.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Most real protocols interact with:

- tokens
- vaults
- oracles
- DEXes
- lending protocols
- bridges

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Inter-contract communication used in:

- ERC20 transfers
- AMM swaps
- lending protocols
- NFT marketplaces
- staking systems
- governance execution

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external call safety
- trust assumptions
- reentrancy risk
- return-value handling
- cross-contract state assumptions

=========================================================
CONTRACT 1:
TARGET CONTRACT
=========================================================
*/
contract Bank {

    mapping(address => uint256) public balances;

    function deposit(
        uint256 _amount
    )
        external
    {
        // VULNERABILITY:
        // msg.sender becomes InterContractCaller
        // during cross-contract calls.
        balances[msg.sender] += _amount;
    }

    function getBalance(
        address _user
    )
        external
        view
        returns (uint256)
    {
        return balances[_user];
    }
}

contract InterContractCaller {

    address public bankAddress;

    uint256 public lastBalance;

    constructor(address _bankAddress) {
        // No validation
        bankAddress = _bankAddress;
    }

    function callDeposit(
        uint256 _amount
    )
        external
    {
        Bank bank = Bank(bankAddress);

        // User expects THEIR balance
        // to increase.
        bank.deposit(_amount);
    }

    function readBalance(
        address _user
    )
        external
    {
        Bank bank = Bank(bankAddress);

        uint256 balance =
            bank.getBalance(_user);

        lastBalance = balance;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy Bank contract.

---------------------------------------------------------

Bank deployed at:

0xABC...

=========================================================
STEP 2:
Deploy InterContractCaller

constructor input:
0xABC...

---------------------------------------------------------

Caller now knows:
Bank contract address.

=========================================================
TRACE:
callDeposit(100)
=========================================================

STEP 1:
User calls:

InterContractCaller.callDeposit(100)

---------------------------------------------------------

STEP 2:
Contract reference created:

Bank bank =
Bank(bankAddress)

---------------------------------------------------------

STEP 3:
External contract call occurs:

bank.deposit(100)

---------------------------------------------------------

EXECUTION CONTEXT SWITCHES

---------------------------------------------------------

Execution enters:
Bank.deposit()

=========================================================
INSIDE BANK CONTRACT
=========================================================

balances[msg.sender] += 100

---------------------------------------------------------

IMPORTANT:

msg.sender is:
InterContractCaller contract

NOT original user.

=========================================================
VERY IMPORTANT msg.sender UNDERSTANDING
=========================================================

Cross-contract call changes:

msg.sender

---------------------------------------------------------

FLOW:

User
  ->
Caller Contract
  ->
Bank Contract

---------------------------------------------------------

Inside Bank:

msg.sender =
Caller contract address

=========================================================
READ FLOW TRACE
=========================================================

CALL:
readBalance(user)

=========================================================

STEP 1:
Caller contract executes.

---------------------------------------------------------

STEP 2:
External view call:

bank.getBalance(user)

---------------------------------------------------------

STEP 3:
Execution enters Bank contract.

---------------------------------------------------------

STEP 4:
Balance returned.

---------------------------------------------------------

STEP 5:
Caller stores result:

lastBalance = returned balance

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy Bank contract

---------------------------------------------------------

STEP 2:
Copy Bank address

---------------------------------------------------------

STEP 3:
Deploy InterContractCaller

Constructor input:
Bank address

---------------------------------------------------------

STEP 4:
Call:
callDeposit(100)

---------------------------------------------------------

STEP 5:
Open Bank contract

---------------------------------------------------------

STEP 6:
Call:
balances(caller_contract_address)

EXPECTED:
100

---------------------------------------------------------

IMPORTANT:
Balance stored for CALLER contract.

=========================================================
IMPORTANT CROSS-CONTRACT UNDERSTANDING
=========================================================

External calls create:

- new execution context
- new msg.sender
- possible reentrancy window
- trust assumptions

=========================================================
INTERFACE-LIKE BEHAVIOR
=========================================================

This line:

Bank(bankAddress)

means:

"Treat this address as Bank contract"

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. REENTRANCY
---------------------------------------------------------

External contract may call back unexpectedly.

---------------------------------------------------------
2. TRUST ASSUMPTIONS
---------------------------------------------------------

Target contract may behave maliciously.

---------------------------------------------------------
3. RETURN VALUE IGNORED
---------------------------------------------------------

Dangerous if call fails silently.

---------------------------------------------------------
4. msg.sender CONFUSION
---------------------------------------------------------

Critical authentication mistakes possible.

=========================================================
VERY IMPORTANT SECURITY CONCEPT
=========================================================

External contract calls are:

UNTRUSTED INTERACTIONS

---------------------------------------------------------

Never assume:
target contract behaves safely.

=========================================================
GAS OBSERVATION
=========================================================

Cross-contract calls:
cost more gas.

---------------------------------------------------------

Reason:
context switching + external execution.

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Which contracts are trusted?
- Can target contract reenter?
- Is msg.sender handled correctly?
- Are return values checked?
- Are external calls ordered safely?

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Malicious contract called externally.

---------------------------------------------------------

During execution:
it reenters vulnerable function.

---------------------------------------------------------

Result:
fund theft.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. Cross-contract execution flow
2. msg.sender changes
3. External interaction timing
4. State-update ordering
5. Reentrancy windows

=========================================================
MINI CHALLENGE
=========================================================

Modify system so that:

1. Add withdraw() function
2. Add external ETH transfer
3. Observe msg.sender changes
4. Add interface contract

BONUS:
Build simple token interaction.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Contracts can call other contracts
- External calls create new execution context
- msg.sender changes during contract calls
- Cross-contract interactions are risky
- External calls may enable reentrancy
- Contract references treat addresses as contracts
- Return values must be checked carefully
- Auditors trace inter-contract execution carefully
- Trust assumptions are security critical
- Inter-contract communication powers DeFi systems

=========================================================
*/
/*
Audit Report

Title: Incorrect Balance Accounting Due To msg.sender Context Change

Severity: Medium because user balances are credited to the caller
contract instead of the intended user

Location:
Contract: Bank
Function: deposit()

Vulnerability Description:

The deposit() function uses msg.sender to determine which
address receives the deposited balance.

When deposit() is called through InterContractCaller,
msg.sender inside Bank becomes the InterContractCaller
contract address rather than the original user address.

As a result, balances are credited to the intermediary
contract instead of the actual user.

Impact:

An attacker or integration contract can cause balances
to be recorded for the wrong address.

This can lead to:

- incorrect accounting
- inaccessible balances
- protocol integration failures
- unexpected business logic behavior

Proof of Concept:

1. Deploy Bank
2. Deploy InterContractCaller using Bank address
3. User calls:

   callDeposit(100)

4. Execution flow:

   User
     ->
   InterContractCaller
     ->
   Bank

5. Inside Bank:

   msg.sender == InterContractCaller

6. State becomes:

   balances[InterContractCaller] = 100

7. User balance remains:

   balances[User] = 0

Root Cause:

The function assumes msg.sender represents the original
user.

However, during external contract calls, msg.sender is
updated to the calling contract address.

Vulnerable code:

    balances[msg.sender] += _amount;

Recommendation:

Pass the intended user address explicitly.

Example:

    function deposit(
        address user,
        uint256 amount
    ) external {
        balances[user] += amount;
    }

And call:

    bank.deposit(
        msg.sender,
        amount
    );

*/

// Patched code
contract BankPatched {

    mapping(address => uint256) public balances;

    function deposit(
        address user,
        uint256 amount
    ) external {
        require(user != address(0), "Invalid user");

        balances[user] += amount;
    }

    function getBalance(
        address user
    ) external view returns (uint256) {
        return balances[user];
    }
}

contract InterContractCallerPatched {

    BankPatched public bank;

    uint256 public lastBalance;

    constructor(address bankAddress) {
        require(
            bankAddress != address(0),
            "Invalid bank address"
        );

        bank = BankPatched(bankAddress);
    }

    function callDeposit(
        uint256 amount
    ) external {
        bank.deposit(
            msg.sender,
            amount
        );
    }

    function readBalance(
        address user
    ) external {
        lastBalance =
            bank.getBalance(user);
    }
}