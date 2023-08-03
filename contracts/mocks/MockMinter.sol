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
    function freeMint(address target, address recipient, uint256 tokenId, uint64 duration) external returns (uint256) {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).mint({ to: recipient, tokenId: tokenId });

        ISubscription(subscription).updateSubscriptionForFree({ target: target, tokenId: tokenId, duration: duration });

        return pfpTokenId;
    }

    /// @param target The address of the contract implementing the access control
    function mint(
        address target,
        address recipient,
        uint256 tokenId,
        uint64 duration
    )
        external
        payable
        returns (uint256)
    {
        // Mint the token
        uint256 pfpTokenId = IMockNFT(mockNFT).mint({ to: recipient, tokenId: tokenId });

        ISubscription(subscription).updateSubscription{ value: msg.value }({
            target: target,
            tokenId: tokenId,
            duration: duration
        });

        return pfpTokenId;
    }
}
