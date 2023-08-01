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

    function mint(address recipient) external returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).mint({ to: recipient, tokenId: 1 });

        // Register subscription for free for 12 days
        ISubscription(subscription).updateSubscription({ tokenId: 1, duration: 10 days });

        return pfpTokenId;
    }
}
