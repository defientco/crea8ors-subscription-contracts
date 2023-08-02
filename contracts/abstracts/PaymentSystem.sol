// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPaymentSystem } from "../interfaces/IPaymentSystem.sol";
import { Admin } from "./Admin.sol";

abstract contract PaymentSystem is IPaymentSystem, Admin {
    /// @notice The price per second for the subscription in native currency.
    uint256 public pricePerSecond;

    constructor(uint256 pricePerSecond_) {
        pricePerSecond = pricePerSecond_;
    }

    /// @inheritdoc IPaymentSystem
    function setPricePerSecond(address target, uint256 newPrice) external override onlyAdmin(target) {
        pricePerSecond = newPrice;
        emit PricePerSecondUpdated(newPrice);
    }

    /// @inheritdoc IPaymentSystem
    function withdraw(address target, address payable to) external override onlyAdmin(target) {
        uint256 amount = address(this).balance;
        if (amount == 0) revert ValueCannotBeZero();

        (bool success,) = to.call{ value: amount }("");
        if (!success) revert ETHTransferFailed();
    }
}
