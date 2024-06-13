// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployDecentralizedStableCoin} from "../../script/DeployDecentralizedStableCoin.s.sol";

contract TestDecentralizedStableCoin is Test {
    error OwnableUnauthorizedAccount(address account);
    error DSC__BurnAmountExceedsBalance();

    DeployDecentralizedStableCoin deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig helperConfig;
    address USER = makeAddr("USER");
    uint256 s_startingBalance = 1000 ether;
    address OWNER;

    function setUp() public {
        vm.deal(USER, s_startingBalance);
        deployer = new DeployDecentralizedStableCoin();
        (dsc, dscEngine, helperConfig) = deployer.run();
        OWNER = dsc.owner();
    }

    function testNotOwnerCanNotMint() public {
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
        dsc.mint(USER, 1 ether);
        vm.stopPrank();
    }

    function testOwnerCanMint() public {
        vm.startPrank(OWNER);
        dsc.mint(USER, 1 ether);
        vm.stopPrank();
    }

    function testOwnerCantBurnWithInsufficientBalance() public {
        uint256 ownerBalance = dsc.balanceOf(OWNER);
        vm.startPrank(OWNER);
        vm.expectRevert(DSC__BurnAmountExceedsBalance.selector);
        dsc.burn(ownerBalance + 1 ether);
        vm.stopPrank();
    }
}
