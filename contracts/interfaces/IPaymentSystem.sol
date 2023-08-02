// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Payment System Interface
/// @notice An interface for the PaymentSystem contract.
interface IPaymentSystem {
    /// @notice Error message for zero value.
    error ValueCannotBeZero();

    /// @notice Error message for failed ETH transfer.
    error ETHTransferFailed();

    /// @dev Emitted when the native currency price is updated.
    /// @param newPrice The new price per second of the native currency.
    event PricePerSecondUpdated(uint256 newPrice);

    /// @notice Sets the price per second of the native currency.
    /// @param target The address of the contract implementing the access control.
    /// @param newPrice The new price per second to be set.
    function setPricePerSecond(address target, uint256 newPrice) external;

    /// @notice Withdraws the native currency from the contract to the specified address.
    /// @param target The address of the contract implementing the access control.
    /// @param to The address to which the native currency should be withdrawn.
    function withdraw(address target, address payable to) external;
}
