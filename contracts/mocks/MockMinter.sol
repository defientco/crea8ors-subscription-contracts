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
    function freeMint(address target, address recipient, uint256 tokenId) external returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).mint({ to: recipient, tokenId: tokenId });

        // Register subscription for free for 10 days
        ISubscription(subscription).updateSubscriptionForFree({ target: target, tokenId: 1, duration: 10 days });

        return pfpTokenId;
    }

    /// @param target The address of the contract implementing the access control
    function mint(address target, address recipient, uint256 tokenId) external payable returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).adminMint({ to: recipient, tokenId: tokenId });

        // Register subscription for free for 30 days for 0.1 ether
        ISubscription(subscription).updateSubscription{ value: 0.1 ether }({
            target: target,
            tokenId: 1,
            duration: 30 days
        });

        return pfpTokenId;
    }
}
