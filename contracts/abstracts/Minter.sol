// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Admin } from "./Admin.sol";

/// @title Minter
/// @dev An abstract contract that implements a basic Minter access control functionality.
abstract contract Minter is Admin {
    /// @notice Only minter can access this function
    error Access_OnlyMinter();

    /// @dev Emitted when the `minter` address is updated.
    /// @param minter The previous minter address.
    /// @param newMinter The new minter address.
    event SetMinter(address indexed minter, address indexed newMinter);

    /// @notice The address of the current minter.
    address public minter;

    /// @dev Modifier to restrict access to only the minter.
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert Access_OnlyMinter();
        }
        _;
    }

    /// @dev Constructor for the Minter contract.
    /// @param _cre8orsNFT The address of the Cre8ors NFT contract.
    /// @param _minter The address of the initial minter.
    constructor(address _cre8orsNFT, address _minter) Admin(_cre8orsNFT) {
        minter = _minter;

        emit SetMinter(address(0), _minter);
    }

    /// @dev Updates the minter address.
    /// @param newMinter The new minter address.
    /// @notice Only the contract admin can call this function.
    function setMinter(address newMinter) public virtual onlyAdmin {
        minter = newMinter;

        emit SetMinter(msg.sender, minter);
    }
}
