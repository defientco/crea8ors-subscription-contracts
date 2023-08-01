// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ICre8ors } from "@crea8ors/interfaces/ICre8ors.sol";
import { IERC721Drop } from "@crea8ors/interfaces/IERC721Drop.sol";

/// @title Admin
/// @notice An abstract contract that restricts access to only the cre8orsNFT contract's admin.
abstract contract Admin {
    ///@notice The address of the collection contract that mints and manages the tokens.
    address public cre8orsNFT;

    /// @dev Modifier that restricts access to only the contract's admin.
    modifier onlyAdmin() {
        if (!ICre8ors(cre8orsNFT).isAdmin(msg.sender)) {
            revert IERC721Drop.Access_OnlyAdmin();
        }
        _;
    }

    /// @dev Constructor for the Admin contract.
    /// @param _cre8orsNFT The address of the Cre8ors NFT contract.
    constructor(address _cre8orsNFT) {
        cre8orsNFT = _cre8orsNFT;
    }
}
