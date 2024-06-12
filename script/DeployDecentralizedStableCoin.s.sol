// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";

contract DeployDecentralizedStableCoin is Script {
    function run() public returns (DecentralizedStableCoin) {
        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        vm.stopBroadcast();

        return dsc;
    }
}
