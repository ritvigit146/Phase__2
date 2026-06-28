// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Storage Collision Demo
CONCEPT: Upgrade/Proxy Risk (delegatecall mismatch)
=========================================================

OBJECTIVE

- Understand storage layout collision in proxy patterns
- See how delegatecall can corrupt state
- Learn why upgradeable contracts are dangerous if misaligned
- Observe proxy vs logic storage interaction

=========================================================
CORE IDEA
=========================================================

delegatecall uses CALLER STORAGE.

If storage layouts differ between:
- Proxy contract
- Logic contract

→ storage collision occurs ❌

=========================================================
VULNERABLE LOGIC CONTRACT (V1)
=========================================================
*/
contract LogicV1Vul {

    // SLOT 0
    uint256 public value;

    // SLOT 1
    address public owner;

    function setValue(uint256 _value) external {
        value = _value;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }
}

contract ProxyBad {

    // SLOT 0
    address public admin;

    // SLOT 1
    address public implementation;

    constructor(address _impl) {
        admin = msg.sender;
        implementation = _impl;
    }

    // VULNERABLE
    function setValue(uint256 _value) external {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setValue(uint256)",
                _value
            )
        );

        require(success, "delegatecall failed");
    }

    // VULNERABLE
    function setOwner(address _owner) external {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setOwner(address)",
                _owner
            )
        );

        require(success, "delegatecall failed");
    }
}

/*
=========================================================
KEY SECURITY INSIGHTS
=========================================================

- delegatecall shares storage with proxy
- storage slot order MUST match exactly
- mismatch = silent corruption (very dangerous)
- upgradeable contracts require strict layout control

=========================================================
AUDITOR CHECKLIST
=========================================================

✔ Does proxy and logic share identical storage layout?
✔ Are new variables appended safely?
✔ Is upgrade mechanism controlled?
✔ Is implementation address protected?
✔ Is storage collision possible via delegatecall?

=========================================================
REAL-WORLD IMPACT
=========================================================

Many DeFi hacks come from:

- broken upgradeable proxies
- storage slot mismatch
- unsafe delegatecall usage
- logic contract upgrades without layout checks

=========================================================
KEY TAKEAWAYS
=========================================================

- delegatecall = shared storage execution
- storage order matters more than logic
- mismatch causes silent corruption
- proxy patterns must be strictly standardized

=========================================================
*/
/*
Audit Report

Title: Storage Collision via delegatecall Due to Mismatched Storage Layout

Severity: High because delegatecall executes the logic contract's code using
the proxy contract's storage. A mismatched storage layout can overwrite
critical proxy variables, leading to storage corruption and potential
contract takeover.

Location:
Contract: ProxyBad
Functions:
- setValue()
- setOwner()

Vulnerability Description:

The ProxyBad contract performs delegatecall to LogicV1 while their storage
layouts are different.

LogicV1 expects:

- Slot 0 → value
- Slot 1 → owner

However, ProxyBad stores:

- Slot 0 → admin
- Slot 1 → implementation

When delegatecall executes, storage writes intended for LogicV1 are applied
to the corresponding storage slots of ProxyBad instead.

As a result, calling setValue() overwrites the admin variable, while calling
setOwner() overwrites the implementation address, causing storage collision
and corrupting the proxy's state.

Impact:

An attacker or incorrect upgrade can overwrite critical proxy storage,
resulting in:

- admin corruption
- implementation address hijacking
- unauthorized upgrades
- permanent proxy corruption
- complete protocol compromise

If the implementation address is overwritten with a malicious contract,
subsequent delegatecalls execute attacker-controlled code.

Proof of Concept:

1. Deploy LogicV1.
2. Deploy ProxyBad using the LogicV1 address.
3. Call:
   setValue(100)
4. Proxy slot 0 (admin) is overwritten instead of updating value.
5. Call:
   setOwner(attackerAddress)
6. Proxy slot 1 (implementation) is overwritten with the attacker-controlled
   address.
7. Future delegatecalls execute malicious logic, compromising the proxy.

Root Cause:

The proxy and logic contracts have incompatible storage layouts.

delegatecall writes directly to the caller's storage slots based on slot
position rather than variable names or types. Because the storage layouts
do not match, critical proxy variables are overwritten.

Recommendation:

Ensure that the proxy and implementation contracts maintain identical and
compatible storage layouts.

Recommended mitigations include:

- Keep storage variables in the same order across upgrades.
- Only append new storage variables; never reorder or remove existing ones.
- Use standardized upgradeable proxy patterns such as OpenZeppelin
  Transparent Proxy or UUPS Proxy.
- Protect delegatecall functionality with proper access control.
- Thoroughly review storage layout compatibility before deploying upgrades.

*/

// Patched code
contract LogicV2 {

    // SLOT 0
    address public implementation;

    // SLOT 1
    address public admin;

    // SLOT 2
    uint256 public value;

    // SLOT 3
    address public owner;

    function setValue(uint256 _value) external {
        value = _value;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }
}

contract ProxySafe {

    // SLOT 0 (matches LogicV2)
    address public implementation;

    // SLOT 1 (matches LogicV2)
    address public admin;

    // SLOT 2 (matches LogicV2)
    uint256 public value;

    // SLOT 3 (matches LogicV2)
    address public owner;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function setValue(uint256 _value)
        external
        onlyAdmin
    {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setValue(uint256)",
                _value
            )
        );

        require(success, "delegatecall failed");
    }

    function setOwner(address _owner)
        external
        onlyAdmin
    {
        (bool success, ) = implementation.delegatecall(
            abi.encodeWithSignature(
                "setOwner(address)",
                _owner
            )
        );

        require(success, "delegatecall failed");
    }
}