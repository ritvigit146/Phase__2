// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Store address in state
CONCEPT: Address persistence
=========================================================

OBJECTIVE

- Learn how Solidity stores Ethereum addresses
- Understand persistent address storage on blockchain
- Learn how addresses are updated and retrieved
- Understand security risks of storing critical addresses

---------------------------------------------------------
WHAT IS AN ADDRESS?
---------------------------------------------------------

An Ethereum address represents:
- user wallet
- smart contract
- admin account
- treasury wallet

Address type in Solidity:
address

Example:
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835Cb2

---------------------------------------------------------
IMPORTANT CONCEPT
---------------------------------------------------------

When an address is stored as a state variable:
- it is saved permanently in storage
- persists across transactions
- remains on blockchain until changed

---------------------------------------------------------
AUDITOR FOCUS
---------------------------------------------------------

Auditors check:

- Who can update stored address?
- Can attacker replace admin wallet?
- Is zero address validation missing?
- Can funds be redirected?
- Is address overwrite protected?

=========================================================
*/
contract StoreAddressVul {

    address public userAddress;

    function storeAddress(address _newAddress) public {
        userAddress = _newAddress;
    }

    function getAddress() public view returns (address) {
        return userAddress;
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

INITIAL STATE

userAddress = 0x0000000000000000000000000000000000000000

This is called ZERO ADDRESS.

---------------------------------------------------------

CALL:
storeAddress(0x123...)

EVM ACTIONS:

1. Transaction reaches contract
2. Address arrives through calldata
3. EVM updates storage slot
4. Address stored permanently
5. Gas consumed for storage write

---------------------------------------------------------

CALL:
getAddress()

EVM ACTIONS:

1. Reads address from storage
2. Returns stored address
3. No state modification occurs

=========================================================
REMIX TESTING
=========================================================

NORMAL FLOW

STEP 1:
Deploy contract

EXPECTED:
userAddress() returns:

0x0000000000000000000000000000000000000000

---------------------------------------------------------

STEP 2:
Copy one Remix account address

Call:
storeAddress(<paste address>)

---------------------------------------------------------

STEP 3:
Call:
userAddress()

EXPECTED:
Stored address returned correctly

---------------------------------------------------------

STEP 4:
Store another address

EXPECTED:
Old address overwritten with new one

=========================================================
EDGE CASE TESTS
=========================================================

TEST:
Store zero address

Call:
storeAddress(0x0000000000000000000000000000000000000000)

EXPECTED:
Works successfully

---------------------------------------------------------

IMPORTANT SECURITY NOTE

In real protocols,
zero address is often INVALID.

Reason:
Funds sent to zero address are usually lost forever.

=========================================================
STORAGE OBSERVATION
=========================================================

Storage slot example:

Initial:
slot0 => 0x0000000000000000000000000000000000000000

After update:
slot0 => user wallet address

After another update:
slot0 overwritten with new address

=========================================================
SECURITY / AUDITOR MINDSET
=========================================================

CRITICAL AUDITOR CHECKS

---------------------------------------------------------
1. MISSING ACCESS CONTROL
---------------------------------------------------------

Currently ANYONE can update address.

Danger:
Attacker can replace important wallet.

---------------------------------------------------------
2. ZERO ADDRESS VALIDATION
---------------------------------------------------------

Problem:
Contract allows zero address.

Real-world issue:
Funds or ownership may become unusable.

Auditors often expect:

require(_newAddress != address(0))

---------------------------------------------------------
3. ADDRESS OVERWRITE RISK
---------------------------------------------------------

If address represents:
- owner
- treasury
- signer
- reward wallet

then unauthorized overwrite becomes critical vulnerability.

=========================================================
ATTACK THINKING
=========================================================

ATTACK SCENARIO

Suppose stored address is treasury wallet.

Attacker calls:

storeAddress(attackerWallet)

Now:
- future funds go to attacker
- protocol treasury hijacked

---------------------------------------------------------

ANOTHER ATTACK

Attacker sets:

address(0)

Impact:
- protocol functionality breaks
- funds may become inaccessible
- ownership can be destroyed

=========================================================
MINI CHALLENGE
=========================================================

Modify contract so that:

1. Only deployer can update address
2. Zero address should be rejected

HINT:

Use:
require(_newAddress != address(0))

=========================================================
IMPORTANT CONCEPTS LEARNED
=========================================================

- Solidity supports address type
- Addresses can be stored permanently
- State variables persist on-chain
- Storage updates overwrite old values
- Zero address is special
- Missing validation creates vulnerabilities
- Access control is essential
- Critical addresses must be protected

=========================================================
*/
/*
Audit Report

Finding 1
Title: Missing Access Control in storeAddress()

Severity: Medium because unauthorized users can change contract state, but the severity depends on what the address is used for

Location

Contract: StoreAddressVul
Function: storeAddress()

Vulnerability Description: The storeAddress() function can be called by any user because no authorization checks are 
implemented.As a result, an attacker can replace the stored address with an arbitrary address under their control.

Impact

If the stored address represents:

treasury wallet
owner address
signer wallet
reward distributor

an attacker may redirect protocol operations or future fund transfers.

Proof of Concept
Deploy contract
Legitimate user stores address:
storeAddress(0x1111111111111111111111111111111111111111);
Attacker calls:
storeAddress(0x2222222222222222222222222222222222222222);
State changes successfully:
userAddress =
0x2222222222222222222222222222222222222222
Root Cause

No access control exists.

function storeAddress(address _newAddress) public {
    userAddress = _newAddress;
}
Recommendation

Restrict updates to the contract owner.

require(msg.sender == owner, "Only owner can update");
Finding 2
Title

Missing Zero Address Validation in storeAddress()

Severity

Low

Location

Contract: StoreAddressVul
Function: storeAddress()

Vulnerability Description

The function allows storing the zero address (address(0)) because no validation is performed on the input.

Impact

If the stored address represents a critical protocol address, assigning the zero address may:

break protocol functionality
disable administrative operations
make funds inaccessible
prevent future interactions
Proof of Concept
Deploy contract
Call:
storeAddress(
    0x0000000000000000000000000000000000000000
);
Transaction succeeds.
State becomes:
userAddress =
0x0000000000000000000000000000000000000000
Root Cause

No validation is performed before updating storage.

userAddress = _newAddress;
Recommendation

Reject zero addresses before storing them.

require(
    _newAddress != address(0),
    "Zero address not allowed"
);
*/

// Patched code
contract StoreAddress {

    address public userAddress;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function storeAddress(address _newAddress) public {
        require(msg.sender == owner, "Only owner can update address");
        require(_newAddress != address(0), "Zero address not allowed");

        userAddress = _newAddress;
    }

    function getAddress() public view returns (address) {
        return userAddress;
    }
}