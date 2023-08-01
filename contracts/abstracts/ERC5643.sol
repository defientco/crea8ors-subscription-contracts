// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC5643 } from "../interfaces/IERC5643.sol";
import { PaymentSystem } from "../abstracts/PaymentSystem.sol";

/// @title ERC5643
/// @notice An abstract contract implementing the IERC5643 interface for managing subscriptions to ERC721 tokens.
abstract contract ERC5643 is IERC5643, PaymentSystem {
    /*//////////////////////////////////////////////////////////////
                             PRIVATE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to store the expiration timestamps for each tokenId representing an active subscription.
    mapping(uint256 tokenId => uint64 expiresAt) private _expirations;

    /*//////////////////////////////////////////////////////////////
                             PUBLIC STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The minimum duration allowed for subscription renewal.
    uint64 public minRenewalDuration;

    /// @notice The maximum duration allowed for subscription renewal. A value of 0 means lifetime extension is allowed.
    uint64 public maxRenewalDuration; // 0 value means lifetime extension

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Constructor for the ERC5643 contract.
    /// @param _cre8orsNFT The address of the Cre8ors NFT contract.
    /// @param _minter The address of the minter e.g. FriendsAndFamilyMinter.
    constructor(address _cre8orsNFT, address _minter) PaymentSystem(_cre8orsNFT, _minter) { }

    /*//////////////////////////////////////////////////////////////
                     USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC5643
    function isRenewable(uint256 /*tokenId*/ ) external view virtual override returns (bool) {
        return _isRenewable();
    }

    /// @inheritdoc IERC5643
    function expiresAt(uint256 tokenId) public view virtual override returns (uint64) {
        return _expirations[tokenId];
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC5643).interfaceId || IERC721(cre8orsNFT).supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                   USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC5643
    function renewSubscription(uint256 tokenId, uint64 duration) external payable virtual override {
        _validateCallerAsOwnerOrApproved({ caller: msg.sender, tokenId: tokenId });

        _validateDurationBetweenMinAndMax(duration);

        _validateRenewalPrice(msg.value, duration);

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    /// @inheritdoc IERC5643
    function cancelSubscription(uint256 tokenId) external payable virtual override {
        _validateCallerAsOwnerOrApproved({ caller: msg.sender, tokenId: tokenId });

        delete _expirations[tokenId];

        emit SubscriptionUpdate(tokenId, 0);
    }

    /*//////////////////////////////////////////////////////////////
                       INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the price to renew a subscription for a specified `duration` in seconds.
    /// @dev This Internal function should be implemented in derived contracts to calculate the renewal price for the
    /// subscription.
    /// @param duration The duration (in seconds) for which the subscription is to be extended.
    /// @return The price (in native currency) required to renew the subscription for the given duration.
    function _getRenewalPrice(uint64 duration) internal view virtual returns (uint256);

    /// @notice Checks whether the subscription is renewable.
    /// @dev This Internal function should be implemented in derived contracts to determine if renewability should be
    /// disabled for all or some tokens.
    /// @return A boolean value indicating whether the subscription can be renewed (true) or not (false).
    function _isRenewable() internal view virtual returns (bool);

    /// @notice Validates that the function caller is either the owner of the token or approved to perform the
    /// operation.
    /// @dev This function checks if the `caller` is approved or the owner of the `tokenId` NFT and reverts with
    /// `CallerNotOwnerNorApproved` error if not.
    /// @param caller The address of the function caller.
    /// @param tokenId The unique identifier of the NFT token for which the validation is performed.
    function _validateCallerAsOwnerOrApproved(address caller, uint256 tokenId) internal view {
        if (!_isApprovedOrOwner(caller, tokenId)) {
            revert CallerNotOwnerNorApproved();
        }
    }

    /// @notice Validates that the provided `duration` falls within the minimum and maximum renewal duration bounds.
    /// @dev This function checks if the `duration` is greater than or equal to the minimum renewal duration and less
    /// than or equal to the maximum renewal duration (if defined).
    /// @param duration The duration (in seconds) to validate.
    function _validateDurationBetweenMinAndMax(uint64 duration) internal view {
        if (duration < minRenewalDuration) {
            revert RenewalTooShort();
        } else if (maxRenewalDuration != 0 && duration > maxRenewalDuration) {
            revert RenewalTooLong();
        }
    }

    /// @notice Validates that the `val` is greater than or equal to the renewal price for the specified `tokenId` and
    /// `duration`.
    /// @dev This function checks if the payment value `val` is sufficient for renewing the subscription represented by
    /// `tokenId` for the provided `duration`.
    /// @param val The payment value provided by the function caller.
    /// @param duration The duration (in seconds) for which the subscription is to be extended.
    function _validateRenewalPrice(uint256 val, uint64 duration) internal view {
        if (val < _getRenewalPrice(duration)) {
            revert InsufficientPayment();
        }
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates the expiration timestamp for a subscription represented by the given `tokenId`.
    /// @dev this function won't check that the tokenId is valid, responsibility is delegated to the caller.
    /// @param tokenId The unique identifier of the subscription token.
    /// @param duration The duration (in seconds) to extend the subscription from the current timestamp.
    function _updateSubscriptionExpiration(uint256 tokenId, uint64 duration) internal virtual {
        uint64 currentExpiration = _expirations[tokenId];
        uint64 newExpiration;

        // Check if the current subscription is new or has expired
        if ((currentExpiration == 0) || (currentExpiration < block.timestamp)) {
            newExpiration = uint64(block.timestamp) + duration;
        } else {
            // If current subscription not expired (extend)
            if (!_isRenewable()) {
                revert SubscriptionNotRenewable();
            }
            newExpiration = currentExpiration + duration;
        }

        _expirations[tokenId] = newExpiration;

        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    /// @dev Internal function to set the minimum renewal duration.
    /// @param duration The new minimum renewal duration (in seconds).
    function _setMinimumRenewalDuration(uint64 duration) internal virtual {
        minRenewalDuration = duration;
    }

    /// @dev Internal function to set the maximum renewal duration.
    /// @param duration The new maximum renewal duration (in seconds).
    function _setMaximumRenewalDuration(uint64 duration) internal virtual {
        maxRenewalDuration = duration;
    }

    // if crea8ors has an `isApprovedOrOwner` then this can be removed
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = IERC721(cre8orsNFT).ownerOf(tokenId);
        return (
            spender == owner || IERC721(cre8orsNFT).isApprovedForAll(owner, spender)
                || IERC721(cre8orsNFT).getApproved(tokenId) == spender
        );
    }
}
