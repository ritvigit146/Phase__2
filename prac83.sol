// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Simple Proxy Contract
CONCEPT: Upgradeable architecture (basic delegatecall proxy)
=========================================================

OBJECTIVE

- Understand proxy + implementation pattern
- Learn how upgrades work using delegatecall
- Separate logic (implementation) from storage (proxy)
- Build minimal upgradeable architecture

=========================================================
CORE IDEA
=========================================================

Proxy holds:
- storage
- implementation address

Logic contract holds:
- functions (code only)

Proxy executes logic via delegatecall.

=========================================================
IMPORTANT RULE

delegatecall = logic runs, but storage belongs to proxy

=========================================================
IMPLEMENTATION CONTRACT (LOGIC V1)
=========================================================
*/
contract LogicV1 {

    uint256 public value;
    address public owner;

    // Anyone can call this through the proxy
    function initialize(address _owner) external {
        owner = _owner;
    }

    function setValue(uint256 _value) external {
        value = _value;
    }
}

contract LogicV2 {

    uint256 public value;
    address public owner;

    function setValue(uint256 _value) external {
        value = _value * 2;
    }

    function setValueIncrement(uint256 _value) external {
        value += _value;
    }
}

contract SimpleProxy {

    address public implementation;
    address public admin;

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function upgrade(address _newImplementation) external {
        require(msg.sender == admin, "Not admin");

        // No validation
        implementation = _newImplementation;
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {

        address impl = implementation;

        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                impl,
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

/*
=========================================================
EXECUTION FLOW
=========================================================

STEP 1: DEPLOY

1. Deploy LogicV1
2. Deploy SimpleProxy with LogicV1 address

=========================================================
STEP 2: INITIALIZE VIA PROXY

CALL:
proxy.call("initialize(address)", owner)

=========================================================

delegatecall happens:
- LogicV1 runs
- Proxy storage updated

Proxy storage becomes:
owner = set owner

=========================================================
STEP 3: SET VALUE (V1 LOGIC)

CALL:
proxy.call("setValue(uint256)", 10)

RESULT:
value = 10 (stored in proxy)

=========================================================
STEP 4: UPGRADE LOGIC

CALL:
upgrade(LogicV2 address)

Only admin can upgrade.

=========================================================
STEP 5: NEW LOGIC EXECUTION

CALL:
proxy.call("setValue(uint256)", 10)

NOW:

LogicV2 runs:
value = 20 (10 * 2)

=========================================================
WHY THIS WORKS

- Storage stays in proxy
- Logic can be swapped anytime
- State remains unchanged across upgrades

=========================================================
IMPORTANT SECURITY INSIGHTS

✔ Proxy holds storage
✔ Logic holds behavior
✔ delegatecall connects both
✔ upgrade changes behavior only

=========================================================
AUDITOR RISKS

- storage collision
- unauthorized upgrade
- broken initialization
- delegatecall injection
- unsafe implementation switching

=========================================================
BEST PRACTICES

- protect upgrade function (onlyOwner / timelock)
- ensure storage layout compatibility
- use audited proxy patterns (UUPS / Transparent)
- never expose implementation directly

=========================================================
KEY TAKEAWAYS

- proxy = storage layer
- implementation = logic layer
- delegatecall = execution bridge
- upgrade = swap logic, not state
- storage safety is critical

=========================================================
*/
/*
Audit Report

Title: Insecure Upgradeable Proxy Design

Severity: High because the proxy contract delegates execution to an
implementation contract while using an incompatible storage layout,
which can corrupt critical proxy state and potentially lead to loss
of administrative control.

Location:
Contract: SimpleProxy
Function: _delegate() (via delegatecall)
Affected Contracts: LogicV1, LogicV2

Vulnerability Description:

The SimpleProxy contract uses delegatecall to execute functions from
LogicV1 and LogicV2. However, the storage layout of the proxy does not
match the storage layout expected by the implementation contracts.

Proxy Storage Layout:

slot 0 -> implementation
slot 1 -> admin

LogicV1 / LogicV2 Storage Layout:

slot 0 -> value
slot 1 -> owner

Since delegatecall executes the implementation code using the proxy's
storage, writing to value or owner actually overwrites implementation
or admin in the proxy contract.

For example:

LogicV1:
value = _value;

actually writes into:

SimpleProxy:
implementation = address(uint160(_value))

Likewise,

owner = _owner;

actually overwrites the admin variable.

This storage collision can corrupt the proxy's critical state and make
future upgrades impossible or allow administrative takeover.

Impact:

Storage corruption may result in:

- implementation address overwritten
- admin address overwritten
- failed delegatecalls
- permanent loss of upgrade functionality
- unexpected contract behavior
- complete proxy compromise

Proof of Concept:

1. Deploy LogicV1.

2. Deploy SimpleProxy using the LogicV1 address.

3. Call through the proxy:

   setValue(100)

4. delegatecall executes LogicV1:

   value = 100;

5. Since value occupies slot 0, slot 0 of the proxy
   (implementation) becomes corrupted.

6. Any future delegatecall may fail because the proxy now points to an
   invalid implementation address.

Similarly,

1. Call:

   initialize(attacker)

2. owner in LogicV1 is written to slot 1.

3. Slot 1 of the proxy (admin) is overwritten.

4. Administrative control of the proxy is lost.

Root Cause:

The proxy and implementation contracts do not share an identical storage
layout.

delegatecall always executes using the caller's storage, so mismatched
storage slots cause implementation variables to overwrite critical proxy
variables.

Recommendation:

Ensure that proxy and implementation storage layouts are compatible.

Recommended mitigations include:

- use ERC-1967 storage slots for implementation and admin
- reserve storage gaps for future upgrades
- maintain identical storage layouts across implementation versions
- use audited proxy standards such as OpenZeppelin Transparent Proxy or UUPS
- protect initialize() with an initializer modifier
- validate new implementation addresses before upgrading
- emit events whenever the implementation is upgraded

*/

// Patched code
contract LogicV1Patched {

    uint256 public value;
    address public owner;
    bool public initialized;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initialize(address _owner) external {

        require(!initialized, "Already initialized");
        require(_owner != address(0), "Invalid owner");

        owner = _owner;
        initialized = true;
    }

    function setValue(uint256 _value) external onlyOwner {
        value = _value;
    }
}

contract LogicV2Patched {

    uint256 public value;
    address public owner;
    bool public initialized;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function setValue(uint256 _value) external onlyOwner {
        value = _value * 2;
    }

    function setValueIncrement(uint256 _value)
        external
        onlyOwner
    {
        value += _value;
    }
}

contract SimpleProxyPatched {

    address public implementation;
    address public admin;

    event Upgraded(address indexed implementation);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _implementation) {

        require(
            _implementation != address(0),
            "Invalid implementation"
        );

        require(
            _implementation.code.length > 0,
            "Not a contract"
        );

        implementation = _implementation;
        admin = msg.sender;
    }

    function upgrade(address _newImplementation)
        external
        onlyAdmin
    {

        require(
            _newImplementation != address(0),
            "Invalid implementation"
        );

        require(
            _newImplementation.code.length > 0,
            "Not a contract"
        );

        implementation = _newImplementation;

        emit Upgraded(_newImplementation);
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {
        _delegate();
    }

    function _delegate() internal {

        address impl = implementation;

        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                impl,
                0,
                calldatasize(),
                0,
                0
            )

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 {
                revert(0, returndatasize())
            }

            default {
                return(0, returndatasize())
            }
        }
    }
}