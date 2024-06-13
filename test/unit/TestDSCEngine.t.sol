// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDecentralizedStableCoin.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TestDSCEngine is Test {
    DeployDecentralizedStableCoin deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("USER");
    uint256 public constant INITIAL_AMOUNT = 1000 ether;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;

    function setUp() public {
        vm.deal(USER, INITIAL_AMOUNT);
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, INITIAL_AMOUNT);
    }

    //////////////////
    // Price tests  //
    //////////////////

    function testGetUsdValue() public view {
        // Suppose we have 15 eth and in our mock each eth is worth 2000 USD
        uint256 ethAmount = 15e18;
        uint256 expectedEthValueInUsd = 30000e18;
        uint256 actualEthUsdValue = dscEngine.getUsdValue(weth, ethAmount);

        assertEq(expectedEthValueInUsd, actualEthUsdValue);
    }

    // Everybody has 0 weth mocked tokens anyway, but ok ¯\_(ツ)_/¯
    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0 ether);
        vm.stopPrank();
    }
}
