// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC721Drop } from "@crea8ors/interfaces/IERC721Drop.sol";

/// @title Admin
/// @notice An abstract contract that restricts access to only the admin.
abstract contract Admin {
    /// @notice Only allow for users with admin access
    modifier onlyAdmin(address _target) {
        if (!isAdmin(_target, msg.sender)) {
            revert IERC721Drop.Access_OnlyAdmin();
        }

        _;
    }

    /// @notice Getter for admin role associated with the contract to handle minting
    /// @param user user address
    /// @return boolean if address is admin
    function isAdmin(address _target, address user) public view returns (bool) {
        return IERC721Drop(_target).isAdmin(user);
    }
}
