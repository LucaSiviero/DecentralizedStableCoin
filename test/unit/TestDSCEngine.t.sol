// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDecentralizedStableCoin.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    address public LIQUIDATOR = makeAddr("LIQUIDATOR");

    uint256 public constant INITIAL_AMOUNT = 1000 ether;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant MINT_AMOUNT = 5 ether;

    function setUp() public {
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dscEngine, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = helperConfig.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, INITIAL_AMOUNT);
        ERC20Mock(weth).mint(LIQUIDATOR, INITIAL_AMOUNT);
    }

    ////////////////////////
    // Constructor tests  //
    ////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
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

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    ///////////////////////////////
    // Deposit collateral tests  //
    ///////////////////////////////

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0 ether);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randomToken = new ERC20Mock();
        console.log(randomToken.name());
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscEngine.depositCollateral(address(randomToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscEngine.getAccountInformation(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscEngine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    /////////////////////
    // Mint DSC tests  //
    /////////////////////

    function testMintDscWithoutDepositingCollateral() public {
        uint256 expectedHealthFactor = 0;
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        dscEngine.mintDsc(1 ether, weth);
        vm.stopPrank();
    }

    //////////////////////
    // Liquidate tests  //
    //////////////////////

    modifier liquidated() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, MINT_AMOUNT);
        vm.stopPrank();

        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(int256(1e18));
        (, int256 price,,,) = AggregatorV3Interface(ethUsdPriceFeed).latestRoundData();
        console.log("Calling healthFactor");
        uint256 userHealthFactor = dscEngine.getHealthFactor(USER);
        console.log(userHealthFactor);

        vm.startPrank(LIQUIDATOR);
        console.log("Calling liquidate");
        ERC20Mock(weth).approve(address(dscEngine), MINT_AMOUNT);
        dscEngine.liquidate(weth, USER, MINT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testLiquidationCantHappenWithGoodHealthFactor() public depositedCollateral {
        vm.startPrank(USER);
        dscEngine.mintDsc(5 ether, weth);
        uint256 healthFactor = dscEngine.getHealthFactor(USER);
        console.log(healthFactor);
        vm.stopPrank();
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        dscEngine.liquidate(weth, USER, AMOUNT_COLLATERAL);
    }

    function testUserGetsLiquidated() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, MINT_AMOUNT);
        vm.stopPrank();

        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(int256(1e8));
        vm.startPrank(LIQUIDATOR);
        console.log("MINT_AMOUNT", MINT_AMOUNT);
        console.log("LIQUIDATOR BALANCE", ERC20Mock(weth).balanceOf(LIQUIDATOR));
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateralAndMintDSC(weth, AMOUNT_COLLATERAL, MINT_AMOUNT);

        console.log("DSCEngine is allowed to move", ERC20Mock(weth).allowance(LIQUIDATOR, address(dscEngine)));
        dscEngine.liquidate(weth, USER, MINT_AMOUNT);
        vm.stopPrank();
    }

    /////////////////////////
    // HealthFactor tests  //
    /////////////////////////

    function testHealthFactorIsBelowThreshold() public depositedCollateral {
        vm.startPrank(USER);
        uint256 amountDscToMint = 5.01 ether;
        vm.expectRevert();
        dscEngine.mintDsc(amountDscToMint, weth);
        vm.stopPrank();
    }
}
