// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployDecentralizedStableCoin is Script {
    address[] public priceFeedsAddresses;
    address[] public tokensAddresses;

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address wethPriceFeed, address wbtcPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        tokensAddresses = [weth, wbtc];
        priceFeedsAddresses = [wethPriceFeed, wbtcPriceFeed];

        vm.startBroadcast(deployerKey);

        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(tokensAddresses, priceFeedsAddresses, address(dsc));
        dsc.transferOwnership(address(engine));

        vm.stopBroadcast();

        return (dsc, engine, helperConfig);
    }
}
