// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: delegatecall Demo
CONCEPT: Context execution (storage of caller contract)
=========================================================

OBJECTIVE

- Understand delegatecall execution model
- See how storage of caller contract is modified
- Learn why delegatecall is powerful AND dangerous
- Observe context (msg.sender, msg.value, storage)

=========================================================
CORE IDEA
=========================================================

delegatecall:

- runs code from another contract
- BUT uses caller’s storage, msg.sender, msg.value

=========================================================
KEY DIFFERENCE

call        → changes callee storage
delegatecall → changes caller storage ❗

=========================================================
LIBRARY CONTRACT (LOGIC ONLY)
=========================================================
*/
contract LogicContractVul {

    uint256 public num;
    address public sender;

    function set(uint256 _num) external payable {
        num = _num;
        sender = msg.sender;
    }
}

contract ProxyContract {

    uint256 public num;
    address public sender;

    address public logic;

    constructor(address _logic) {
        logic = _logic;
    }

    // VULNERABLE
    function setViaDelegate(uint256 _num) external payable {

        (bool success, ) = logic.delegatecall(
            abi.encodeWithSignature(
                "set(uint256)",
                _num
            )
        );

        require(success, "delegatecall failed");
    }
}
/*
Audit Report

Title: Unsafe delegatecall to External Contract

Severity: High because delegatecall executes external contract code in the
storage context of the calling contract, allowing arbitrary modification
of the caller's state if the target contract is malicious or compromised.

Location:
Contract: ProxyContract
Function: setViaDelegate()

Vulnerability Description:

The setViaDelegate() function performs a delegatecall to the address stored
in the logic variable without verifying that the target contract is trusted.

Because delegatecall executes the target contract's code using the storage,
msg.sender, and msg.value of the ProxyContract, a malicious logic contract
can overwrite storage variables, corrupt contract state, or execute arbitrary
logic within the proxy contract.

Impact:

An attacker controlling or replacing the logic contract could:

- overwrite critical storage variables
- change ownership variables
- corrupt protocol state
- steal funds if the proxy manages ETH or tokens
- permanently brick the contract

Since delegatecall executes with the caller's storage context, the impact
can be equivalent to full contract compromise.

Proof of Concept:

1. Deploy a malicious logic contract containing a function that modifies
   storage variables (e.g., owner or logic).

2. Deploy ProxyContract using the malicious logic contract address.

3. Call:
   setViaDelegate(100)

4. The malicious code executes through delegatecall and modifies the
   ProxyContract's storage instead of its own.

5. The proxy contract's state is successfully corrupted.

Root Cause:

The contract performs delegatecall to an external contract without ensuring
that the implementation contract is trusted or immutable.

delegatecall executes external code while preserving the storage context of
the caller, making it inherently dangerous when used with untrusted targets.

Recommendation:

Only delegatecall to trusted implementation contracts.

Recommended mitigations include:

- validate the logic address during deployment
- make the implementation address immutable if upgrades are unnecessary
- restrict sensitive functions using access control
- use audited upgradeable proxy patterns for upgradeable systems
- never delegatecall to user-controlled addresses

*/

// Patched code
contract LogicContract {

    uint256 public num;
    address public sender;

    function set(uint256 _num) external payable {
        num = _num;
        sender = msg.sender;
    }
}

contract SecureProxy {

    uint256 public num;
    address public sender;

    address public immutable logic;
    address public owner;

    constructor(address _logic) {
        require(_logic != address(0), "Invalid logic");

        logic = _logic;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setViaDelegate(uint256 _num)
        external
        payable
        onlyOwner
    {
        (bool success, ) = logic.delegatecall(
            abi.encodeWithSignature(
                "set(uint256)",
                _num
            )
        );

        require(success, "delegatecall failed");
    }
}