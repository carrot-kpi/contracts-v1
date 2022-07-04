pragma solidity >=0.8.0;

import {IERC20Upgradeable} from "oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IKPIToken} from "./IKPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token interface
/// @dev Interface for the ERC20 KPI token contract.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
interface IERC20KPIToken is IKPIToken, IERC20Upgradeable {
    struct OracleData {
        uint256 templateId;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 weight;
        bytes data;
    }

    struct Collateral {
        address token;
        uint256 amount;
        uint256 minimumPayout;
    }

    struct FinalizableOracle {
        address addrezz;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 finalResult;
        uint256 weight;
        bool finalized;
    }

    struct RedeemedCollateral {
        address token;
        uint256 amount;
    }

    function recoverERC20(address _token, address _receiver) external;

    function registerRedemption() external;

    function redeemCollateral(address _token, address _receiver) external;
}
