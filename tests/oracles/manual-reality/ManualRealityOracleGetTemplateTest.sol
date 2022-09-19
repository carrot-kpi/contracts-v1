pragma solidity 0.8.17;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {RealityV3Oracle} from "../../../contracts/oracles/RealityV3Oracle.sol";
import {IOraclesManager1} from "../../../contracts/interfaces/oracles-managers/IOraclesManager1.sol";
import {Template} from "../../../contracts/interfaces/IBaseTemplatesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle get template test
/// @dev Tests template query in manual Reality oracle template.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracleGetTemplateTest is BaseTestSetup {
    function testSuccess() external {
        RealityV3Oracle oracleInstance = RealityV3Oracle(
            Clones.clone(address(realityV3OracleTemplate))
        );
        Template memory _template = oraclesManager.template(1);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        vm.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestionWithMinBond(uint256,string,address,uint32,uint32,uint256,uint256)"
            ),
            abi.encode(_questionId)
        );
        vm.prank(address(oraclesManager));
        oracleInstance.initialize(
            address(1),
            _template.id,
            _template.version,
            abi.encode(
                _realityAddress,
                address(1),
                0,
                "a",
                60,
                block.timestamp + 60
            )
        );

        assertEq(oracleInstance.template().id, _template.id);

        vm.clearMockedCalls();
    }
}
