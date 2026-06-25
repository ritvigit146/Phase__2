// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Make external call after state update
CONCEPT: Safer execution
=========================================================

OBJECTIVE

- Learn safer external-call ordering
- Understand CEI security pattern
- Prevent basic reentrancy vulnerabilities
- Learn secure execution sequencing

---------------------------------------------------------
CORE IDEA
---------------------------------------------------------

Safe pattern:

1. CHECKS
2. EFFECTS
3. INTERACTIONS

---------------------------------------------------------

Known as:
CEI pattern.

---------------------------------------------------------
IMPORTANT UNDERSTANDING
---------------------------------------------------------

State must update BEFORE
external interaction.

---------------------------------------------------------

This reduces:
reentrancy attack surface.

---------------------------------------------------------
WHY THIS MATTERS
---------------------------------------------------------

Incorrect external-call ordering caused:
major DeFi hacks.

---------------------------------------------------------
REAL-WORLD USAGE
---------------------------------------------------------

Safe ordering used in:

- vault withdrawals
- token redemptions
- staking systems
- lending protocols
- treasury payments

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors inspect:

- external-call timing
- storage-update order
- CEI violations
- reentrancy windows
- interaction safety

=========================================================
SAFE CONTRACT
=========================================================
*/

contract SafeBank {

    /*
        USER BALANCES
    */
    mapping(address => uint256) public balances;

    /*
        TRACK TOTAL ETH
    */
    uint256 public totalDeposits;

    /*
    =====================================================
    DEPOSIT ETH
    =====================================================
    */

    function deposit()
        external
        payable
    {

        /*
            Store user balance.
        */
        balances[msg.sender] += msg.value;

        /*
            Update global accounting.
        */
        totalDeposits += msg.value;
    }

    /*
    =====================================================
    SAFE WITHDRAW
    =====================================================

    Follows:
    Checks -> Effects -> Interactions
    */

    function withdraw(
        uint256 _amount
    )
        external
    {

        /*
        =================================================
        CHECKS
        =================================================

        Validate user balance FIRST.
        */

        require(
            balances[msg.sender] >= _amount,
            "Insufficient balance"
        );

        /*
        =================================================
        EFFECTS
        =================================================

        Update storage BEFORE external call.
        */

        balances[msg.sender] -= _amount;

        totalDeposits -= _amount;

        /*
        =================================================
        INTERACTIONS
        =================================================

        External call happens LAST.
        */

        (bool success, ) =
            payable(msg.sender).call{
                value: _amount
            }("");

        /*
            Ensure ETH transfer succeeded.
        */
        require(
            success,
            "ETH transfer failed"
        );
    }

    /*
    =====================================================
    CHECK CONTRACT BALANCE
    =====================================================
    */

    function contractBalance()
        external
        view
        returns (uint256)
    {

        return address(this).balance;
    }
}

/*
=========================================================
MALICIOUS TEST CONTRACT
=========================================================
*/

contract ReentryTester {

    /*
        TARGET SAFE CONTRACT
    */
    SafeBank public target;

    /*
        TRACK REENTRY ATTEMPTS
    */
    uint256 public attackCounter;

    /*
        CONSTRUCTOR
    */
    constructor(address _target)
    {

        target = SafeBank(_target);
    }

    /*
    =====================================================
    DEPOSIT INTO TARGET
    =====================================================
    */

    function depositToTarget()
        external
        payable
    {

        target.deposit{value: msg.value}();
    }

    /*
    =====================================================
    START WITHDRAW
    =====================================================
    */

    function attack()
        external
    {

        /*
            Attempt withdrawal.
        */
        target.withdraw(1 ether);
    }

    /*
    =====================================================
    RECEIVE FUNCTION
    =====================================================

    Attempt reentrancy attack.
    */

    receive()
        external
        payable
    {

        attackCounter++;

        /*
            Try reentering target.
        */
        if (
            address(target).balance >= 1 ether
        ) {

            /*
                THIS FAILS SAFELY

                Why?

                Balance already reduced.
            */
            try target.withdraw(1 ether) {

            } catch {

            }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1:
Deploy SafeBank

---------------------------------------------------------

STEP 2:
Deposit ETH into SafeBank

=========================================================
STEP 3
=========================================================

Deploy ReentryTester

Input:
SafeBank address

=========================================================
STEP 4
=========================================================

Call:
depositToTarget()

VALUE:
1 ETH

=========================================================
STEP 5
=========================================================

Call:
attack()

=========================================================
SAFE EXECUTION TRACE
=========================================================

STEP 1:
withdraw(1 ether)

---------------------------------------------------------

Balance validation passes.

=========================================================
STEP 2
=========================================================

Storage updated FIRST.

---------------------------------------------------------

balances[attacker] -= 1 ether

---------------------------------------------------------

NEW VALUE:
0

=========================================================
STEP 3
=========================================================

External call executes:

call{value: 1 ether}()

---------------------------------------------------------

Control transfers to:
ReentryTester.receive()

=========================================================
STEP 4
=========================================================

Attacker attempts reentrancy.

---------------------------------------------------------

Calls:
target.withdraw(1 ether)

=========================================================
IMPORTANT
=========================================================

Balance already reduced.

---------------------------------------------------------

balances[attacker] = 0

---------------------------------------------------------

require() fails.

---------------------------------------------------------

Reentrancy blocked naturally.

=========================================================
WHY SAFE ORDERING WORKS
=========================================================

Attacker sees:
UPDATED state.

---------------------------------------------------------

Temporary inconsistent state
never exposed.

=========================================================
IMPORTANT SECURITY PRINCIPLE
=========================================================

Update internal accounting
BEFORE external interaction.

=========================================================
CEI PATTERN
=========================================================

---------------------------------------------------------
1. CHECKS
---------------------------------------------------------

Validate conditions.

---------------------------------------------------------
2. EFFECTS
---------------------------------------------------------

Update storage.

---------------------------------------------------------
3. INTERACTIONS
---------------------------------------------------------

External calls LAST.

=========================================================
REMIX TESTING
=========================================================

STEP 1:
Deploy SafeBank

---------------------------------------------------------

STEP 2:
Deposit several ETH

---------------------------------------------------------

STEP 3:
Deploy ReentryTester

Input:
SafeBank address

---------------------------------------------------------

STEP 4:
Call:
depositToTarget()

VALUE:
1 ETH

---------------------------------------------------------

STEP 5:
Call:
attack()

---------------------------------------------------------

STEP 6:
Observe:

Attack fails safely.

---------------------------------------------------------

STEP 7:
Call:
attackCounter()

EXPECTED:
receive() triggered,
but reentrancy unsuccessful.

=========================================================
IMPORTANT AUDITOR UNDERSTANDING
=========================================================

Safe ordering:
reduces reentrancy risk greatly.

---------------------------------------------------------

BUT:
not always sufficient alone.

=========================================================
ADDITIONAL DEFENSES
=========================================================

Modern contracts also use:

- ReentrancyGuard
- pull-payment model
- minimal external calls

=========================================================
COMMON AUDIT RISKS
=========================================================

---------------------------------------------------------
1. STATE UPDATED TOO LATE
---------------------------------------------------------

Classic reentrancy issue.

---------------------------------------------------------
2. CROSS-FUNCTION REENTRANCY
---------------------------------------------------------

Different functions interact dangerously.

---------------------------------------------------------
3. CALLBACK MANIPULATION
---------------------------------------------------------

External contracts alter execution.

---------------------------------------------------------
4. UNCHECKED EXTERNAL CALLS
---------------------------------------------------------

Transfer failures ignored.

=========================================================
IMPORTANT ATTACK THINKING
=========================================================

Attackers search for:

- external calls
- delayed storage updates
- recursive entry points
- callback execution

---------------------------------------------------------

Safe ordering blocks many attacks.

=========================================================
REAL AUDITOR PROCESS
=========================================================

Auditors trace:

1. State before call
2. State after call
3. External execution timing
4. Reentrancy windows
5. Invariant preservation

=========================================================
WHY CEI IS IMPORTANT
=========================================================

CEI reduces exposure to:

- reentrancy
- inconsistent state
- recursive withdrawals
- accounting corruption

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

Auditors ask:

- Are effects before interactions?
- Can attacker reenter?
- Is temporary state exposed?
- Are balances updated safely?
- Can callbacks manipulate logic?

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Add ReentrancyGuard
2. Add event logging
3. Add vulnerable version
4. Compare safe vs unsafe behavior

BONUS:
Create cross-function reentrancy test.

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- External calls are dangerous
- State should update before interaction
- CEI pattern improves security
- Reentrancy exploits delayed updates
- Safe ordering reduces attack surface
- External contracts are untrusted
- receive()/fallback() enable callbacks
- Auditors inspect execution order carefully
- Reentrancy depends heavily on timing
- Safer execution prevents many exploits

=========================================================
*/