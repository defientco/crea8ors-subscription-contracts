/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ISubscription
/// @dev Interface for managing subscriptions to NFTs.
interface ISubscription {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice The subscription associated with the provided token ID is invalid or has expired.
    error InvalidSubscription();

    error LengthMismatch();

    error InvalidLength();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                           CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the subscription for the given `tokenId` is valid.
    /// @param tokenId The unique identifier of the NFT token.
    /// @return A boolean indicating if the subscription is valid.
    function isSubscriptionValid(uint256 tokenId) external view returns (bool);

    /// @notice Validates the subscription for the given `tokenId`.
    /// Throws if `tokenId` subscription has expired.
    /// @param tokenId The unique identifier of the NFT token.
    /// @return A boolean indicating if the subscription is valid.
    function validateSubscription(uint256 tokenId) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                         NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////   updateSubscriptionForFree variants   //////////*/

    /// @notice Extends the subscription for the given `tokenId` with a specified `duration` for free.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param target The address of the contract implementing the access control
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param tokenId The unique identifier of the NFT token to be subscribed.
    function updateSubscriptionForFree(address target, uint64 duration, uint256 tokenId) external;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `duration` for free.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param target The address of the contract implementing the access control
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    function updateSubscriptionForFree(address target, uint64 duration, uint256[] calldata tokenIds) external;

    /*//////////////   updateSubscription variants   /////////////*/

    /// @notice Extends the subscription for the given `tokenId` with a specified `duration`, using native currency as
    /// payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param target The address of the contract implementing the access control
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param tokenId The unique identifier of the NFT token to be subscribed.
    function updateSubscription(address target, uint64 duration, uint256 tokenId) external payable;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `duration`, using native currency as
    /// payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param target The address of the contract implementing the access control
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    function updateSubscription(address target, uint64 duration, uint256[] calldata tokenIds) external payable;
}
