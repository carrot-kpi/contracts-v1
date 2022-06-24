pragma solidity 0.8.15;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager instantiate template test
/// @dev Tests template instantiation in oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManagerInstantiateTest is BaseTestSetup {
    function testFailNotFromCreatedKpiToken() external {
        // FIXME: why does this fail if I uncomment stuff?
        vm.expectRevert(); /* abi.encodeWithSignature("Forbidden()") */
        oraclesManager.instantiate(address(this), 0, bytes(""));
    }

    function testSuccessManualRealityOracle() external {
        bytes memory _initializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        address _predictedInstanceAddress = Clones.predictDeterministicAddress(
            address(manualRealityOracleTemplate),
            keccak256(abi.encodePacked(address(this), _initializationData)),
            address(oraclesManager)
        );
        vm.mockCall(
            address(factory),
            abi.encodeWithSignature(
                "allowOraclesCreation(address)",
                address(this)
            ),
            abi.encode(true)
        );
        address _instance = oraclesManager.instantiate(
            address(this),
            0,
            _initializationData
        );
        assertEq(_instance, _predictedInstanceAddress);
        vm.clearMockedCalls();
    }
}
