// SPDX-License-Identifier: MIT

// This file will test all the invariant properties of our system.

// First thing is to understand what are the invariants here

// 1. The total supply of DSC should always be less than the total value of collateral

// 2. Getter view functions should never revert (This is actually an evergreen for invariant tests)

pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDecentralizedStableCoin.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract Inviariants is StdInvariant, Test {
    DeployDecentralizedStableCoin public deployer;
    DecentralizedStableCoin public dsc;
    DSCEngine public dscEngine;
    HelperConfig public helperConfig;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    Handler public handler;
    address public USER = makeAddr("USER");

    function setUp() external {
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (,, weth, wbtc,) = helperConfig.activeNetworkConfig();
        //targetContract(address(dscEngine));
        handler = new Handler(dscEngine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupplyV2() public view {
        // get the value of all the collateral in the protocol
        // Compare it to all the debt (dsc)

        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscEngine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValue(wbtc, totalWbtcDeposited);

        uint256 timesMintIsCalled = handler.timesMintCalled();

        console.log("wethValue", wethValue);
        console.log("wbtcValue", wbtcValue);
        console.log("totalSupply", totalSupply);
        console.log("timesMintDscIsCalled", timesMintIsCalled);

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        dscEngine.getAdditionalFeedPrecision();
        dscEngine.getPrecision();
        dscEngine.getLiquidationBonus();
        dscEngine.getCollateralTokens();
    }
}
