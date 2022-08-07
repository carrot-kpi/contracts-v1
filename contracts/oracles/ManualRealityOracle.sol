pragma solidity 0.8.15;

import {Initializable} from "oz/proxy/utils/Initializable.sol";
import {IOracle} from "../interfaces/oracles/IOracle.sol";
import {IOraclesManager1} from "../interfaces/oracles-managers/IOraclesManager1.sol";
import {IKPIToken} from "../interfaces/kpi-tokens/IKPIToken.sol";
import {IReality} from "../interfaces/external/IReality.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle
/// @dev An oracle template imlementation leveraging Reality.eth
/// crowdsourced, manual oracle to get data about real-world events
/// on-chain. Since the oracle is crowdsourced, it's extremely flexible,
/// and any condition that can be put into text can leverage Reality.eth
/// as an oracle. The setup is of great importance to ensure the safety
/// of the solution (question timeout, opening timestamp, arbitrator atc must be set
/// with care to avoid unwanted results).
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ManualRealityOracle is IOracle, Initializable {
    bool public finalized;
    address public kpiToken;
    address internal oraclesManager;
    address internal reality;
    IOraclesManager1.Template internal oracleTemplate;
    bytes32 internal questionId;
    string internal question;

    error Forbidden();
    error ZeroAddressKpiToken();
    error ZeroAddressReality();
    error ZeroAddressArbitrator();
    error InvalidQuestion();
    error InvalidQuestionTimeout();
    error InvalidOpeningTimestamp();

    event Initialize(
        address indexed kpiToken,
        uint256 indexed templateId,
        bytes data
    );
    event Finalize(uint256 result);

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the oracles manager contract, in turn invoked by a KPI
    /// token template at creation-time. For more info on some of this parameters check
    /// out the Reality.eth docs here: https://reality.eth.limo/app/docs/html/dapp.html#.
    /// @param _kpiToken The address of the KPI token to which the oracle must be linked to.
    /// This address is also used to know to which contract to report results back to.
    /// @param _templateId The id of the template.
    /// @param _data An ABI-encoded structure forwarded by the created KPI token from the KPI token
    /// creator, containing the initialization parameters for the oracle template.
    /// In particular the structure is formed in the following way:
    /// - `address _reality`: The address of the Reality.eth contract of choice in a specific network.
    /// - `address _arbitrator`: The arbitrator for the Reality.eth question.
    /// - `uint256 _realityTemplateId`: The template id for the Reality.eth question.
    /// - `string memory _question`: The question that must be submitted to Reality.eth.
    /// - `uint32 _questionTimeout`: The question timeout as described in the Reality.eth docs (linked above).
    /// - `uint32 _openingTimestamp`: The question opening timestamp as described in the Reality.eth docs (linked above).
    /// - `uint256 minimumBond`: The minimum bond that can be used to answer the question.
    function initialize(
        address _kpiToken,
        uint256 _templateId,
        bytes calldata _data
    ) external payable override initializer {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _reality,
            address _arbitrator,
            uint256 _realityTemplateId,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _openingTimestamp,
            uint256 _minimumBond
        ) = abi.decode(
                _data,
                (address, address, uint256, string, uint32, uint32, uint256)
            );

        if (_reality == address(0)) revert ZeroAddressReality();
        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_openingTimestamp <= block.timestamp)
            revert InvalidOpeningTimestamp();

        oraclesManager = msg.sender;
        kpiToken = _kpiToken;
        reality = _reality;
        oracleTemplate = IOraclesManager1(msg.sender).template(_templateId);
        question = _question;
        questionId = IReality(_reality).askQuestionWithMinBond{
            value: msg.value
        }(
            _realityTemplateId,
            _question,
            _arbitrator,
            _questionTimeout,
            _openingTimestamp,
            0,
            _minimumBond
        );

        emit Initialize(_kpiToken, _templateId, _data);
    }

    /// @dev Once the question is finalized on Reality.eth, this must be manually called to
    /// report back the result to the linked KPI token. This also marks the oracle as finalized.
    function finalize() external {
        if (finalized) revert Forbidden();
        finalized = true;
        uint256 _result = uint256(IReality(reality).resultFor(questionId));
        IKPIToken(kpiToken).finalize(_result);
        emit Finalize(_result);
    }

    /// @dev View function returning all the most important data about the oracle, in
    /// an ABI-encoded structure. The structure pretty much includes all the initialization
    /// data and some.
    /// @return The ABI-encoded data.
    function data() external view override returns (bytes memory) {
        address _reality = reality; // gas optimization
        bytes32 _questionId = questionId; // gas optimization
        return
            abi.encode(
                _reality,
                _questionId,
                IReality(_reality).getArbitrator(_questionId),
                question,
                IReality(_reality).getTimeout(_questionId),
                IReality(_reality).getOpeningTS(_questionId)
            );
    }

    /// @dev View function returning info about the template used to instantiate this oracle.
    /// @return The template struct.
    function template()
        external
        view
        override
        returns (IOraclesManager1.Template memory)
    {
        return oracleTemplate;
    }
}
