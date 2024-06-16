/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin
 * @author Luca Siviero
 * Collateral: exogenous (ETH and BTC)
 * Minting: Algorithmic
 * Relative Stability: Anchored to USD
 *
 * This is the contract meant to be governed by DSCEngine. This contract is just the EC20 implementation of the stable coin system
 *
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DSC__MustBeMoreThanZero();
    error DSC__BurnAmountExceedsBalance();
    error DSC__NotZeroAddress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DSC__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DSC__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DSC__NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DSC__MustBeMoreThanZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
