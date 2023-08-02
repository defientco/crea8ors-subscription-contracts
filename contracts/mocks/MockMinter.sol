// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISubscription } from "../interfaces/ISubscription.sol";
import { IMockNFT } from "./MockNFT.sol";

// minter
// for example -> `FriendsAndFamilyMinter`
contract MockMinter {
    address public mockNFT;
    address public subscription;

    constructor(address _mockNFT, address _subscription) {
        mockNFT = _mockNFT;
        subscription = _subscription;
    }

    /// @param target The address of the contract implementing the access control
    function mint(address target, address recipient) external returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).mint({ to: recipient, tokenId: 1 });

        // Register subscription for free for 12 days
        ISubscription(subscription).updateSubscriptionForFree({ target: target, tokenId: 1, duration: 10 days });

        return pfpTokenId;
    }
}
