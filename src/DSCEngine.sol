/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DSCengine
 * @author Luca Siviero
 * The system is designed to be as minimal as possible, with the goal of maintaining 1 token == 1$ peg.
 * This stable coin has the properties:
 * - Exogeneous Collateral
 * - Dollar pegged
 * - Algorithmically stable
 *
 *
 * Our DSC system should always be overcollateralized. At no point in time, the value of all collateral will be <= the $backed value of all DSC.
 * @notice This contract is the core of the DSC system. It handles all the logic: minting and redeeming DSC, depositing and withdrowing collateral.
 * @notice This contrac is very loosely based on the Maker DAO (DSS) system.
 */
contract DSCEngine {
    error DSCEngine__NeedsMoreThanZero();

    mapping(address => address) private s_tokenToAllowed;

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__NeedsMoreThanZero();
            _;
        }
    }

    modifier isAllowedToken(address token) {
        _;
    }

    constructor() {}

    function depositCollateralAndMintDSC() external {}

    /**
     *
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    ) external moreThanZero(amountCollateral) {}

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFacotr() external view {}
}
