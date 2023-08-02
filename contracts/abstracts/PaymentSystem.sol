// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPaymentSystem } from "../interfaces/IPaymentSystem.sol";
import { Admin } from "./Admin.sol";

abstract contract PaymentSystem is IPaymentSystem, Admin {
    /// @notice The price per second for the subscription in native currency.
    uint256 public pricePerSecond;

    /// @inherits IPaymentSystem
    function setPricePerSecond(address target, uint256 newPrice) external override onlyAdmin(target) {
        pricePerSecond = newPrice;
        emit PricePerSecondUpdated(newPrice);
    }

    /// @inherits IPaymentSystem
    function withdraw(address target, address payable to) external override onlyAdmin(target) {
        if (address(this).balance == 0) revert ValueCannotBeZero();

        (bool success,) = to.call{ value: amount }("");
        if (!success) revert ETHTransferFailed();
    }
}
