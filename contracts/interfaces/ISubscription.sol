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

    /// @notice Renews the subscription to an NFT with the specified `tokenId`, using the accepted ERC20 token as the
    /// payment method.
    /// @dev This function can be called by NFT owners to renew their subscriptions using ERC20 tokens as payment.
    /// Throws if `tokenId` is not a valid NFT.
    /// @param tokenId The unique identifier of the NFT token to be renewed.
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param erc20 The address of the ERC20 token to be used for payment.
    function renewSubscriptionWithERC20Payment(uint256 tokenId, uint64 duration, address erc20) external payable;

    /*//////////   updateSubscriptionForFree variants   //////////*/

    /// @notice Extends the subscription for the given `tokenId` with a specified `duration` for free.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenId The unique identifier of the NFT token to be subscribed.
    /// @param duration The duration (in seconds) to extend the subscription for.
    function updateSubscriptionForFree(uint256 tokenId, uint64 duration) external;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `duration` for free.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param duration The duration (in seconds) to extend the subscription for.
    function updateSubscriptionForFree(uint256[] calldata tokenIds, uint64 duration) external;

    /// @notice Extends the subscriptions for the given `tokenIds` with specified `durations` for free.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param durations An array of durations (in seconds) for which the subscriptions are to be extended.
    function updateSubscriptionForFree(uint256[] calldata tokenIds, uint64[] calldata durations) external;

    /*//////////////   updateSubscription variants   /////////////*/

    /// @notice Extends the subscription for the given `tokenId` with a specified `duration`, using native currency as
    /// payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenId The unique identifier of the NFT token to be subscribed.
    /// @param duration The duration (in seconds) to extend the subscription for.
    function updateSubscription(uint256 tokenId, uint64 duration) external payable;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `duration`, using native currency as
    /// payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param duration The duration (in seconds) to extend the subscription for.
    function updateSubscription(uint256[] calldata tokenIds, uint64 duration) external payable;

    /// @notice Extends the subscription for the given `tokenIds` with specified `durations`, using native currency as
    /// payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param durations An array of durations (in seconds) for which the subscriptions are to be extended.
    function updateSubscription(uint256[] calldata tokenIds, uint64[] calldata durations) external payable;

    /*//////   updateSubscriptionWithERC20Payment variants   /////*/

    /// @notice Extends the subscription for the given `tokenId` with a specified `duration`, using the accepted ERC20
    /// token as payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenId The unique identifier of the NFT token to be subscribed.
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param erc20 The address of the ERC20 token to be used for payment.
    function updateSubscriptionWithERC20Payment(uint256 tokenId, uint64 duration, address erc20) external;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `duration`, using the accepted ERC20
    /// token as payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param erc20 The address of the ERC20 token to be used for payment.
    function updateSubscriptionWithERC20Payment(uint256[] calldata tokenIds, uint64 duration, address erc20) external;

    /// @notice Extends the subscription for the given `tokenIds` with a specified `durations`, using the accepted ERC20
    /// token as payment.
    /// @dev This function is meant to be called by the minter when minting the NFT to subscribe.
    /// @param tokenIds An array of unique identifiers of the NFT tokens to update the subscriptions for.
    /// @param durations An array of durations (in seconds) for which the subscriptions are to be extended.
    /// @param erc20 The address of the ERC20 token to be used for payment.
    function updateSubscriptionWithERC20Payment(
        uint256[] calldata tokenIds,
        uint64[] calldata durations,
        address erc20
    )
        external;
}
