// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=========================================================
PRACTICAL: Chain multiple external calls
PATCHED VERSION
=========================================================
*/

contract ContractC {

    uint256 public counter;

    function finalStep() external {
        counter++;
    }

    function failStep() external pure {
        revert("Contract C failure");
    }
}

/*
=========================================================
CONTRACT B (PATCHED)
=========================================================
*/
contract ContractB {

    ContractC public contractC;
    uint256 public middleCounter;

    constructor(address _contractC) {
        contractC = ContractC(_contractC);
    }

    /*
    =====================================================
    SAFE EXTERNAL CALL
    =====================================================
    */
    function callFinalStep() external {

        middleCounter++;

        // Low-level call
        (bool success, ) = address(contractC).call(
            abi.encodeWithSignature("finalStep()")
        );

        // PATCH: Check return value
        require(success, "External call failed");
    }

    /*
    =====================================================
    SAFE FAILING CALL
    =====================================================
    */
    function callFailingStep() external {

        middleCounter++;

        (bool success, ) = address(contractC).call(
            abi.encodeWithSignature("failStep()")
        );

        // PATCH: Revert if downstream call failed
        require(success, "Contract C failure");
    }
}

/*
=========================================================
CONTRACT A
=========================================================
*/
contract ContractA {

    ContractB public contractB;
    uint256 public entryCounter;

    constructor(address _contractB) {
        contractB = ContractB(_contractB);
    }

    /*
    =====================================================
    START SUCCESSFUL CHAIN
    =====================================================
    */
    function startChain() external {

        entryCounter++;

        contractB.callFinalStep();
    }

    /*
    =====================================================
    START FAILING CHAIN
    =====================================================
    */
    function startFailingChain() external {

        entryCounter++;

        contractB.callFailingStep();
    }
}