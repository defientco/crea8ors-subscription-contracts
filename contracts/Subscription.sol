// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20TransferHelper } from "./libraries/ERC20TransferHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISubscription } from "./interfaces/ISubscription.sol";
import { ERC5643 } from "./abstracts/ERC5643.sol";

// TODO FIX - Known issue -> price calculation and validation

contract Subscription is ISubscription, ERC5643 {
    /*//////////////////////////////////////////////////////////////
                            PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice The default duration for subscriptions, set to 365 days (1 year).
    uint64 public constant DEFAULT_SUBSCRIPTION_DURATION = 365 days;

    /*//////////////////////////////////////////////////////////////
                             PRIVATE STORAGE
    //////////////////////////////////////////////////////////////*/

    bool private _renewable;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Initializes the Subscription contract with the address of the NFT and the minter contract addresses.
    /// @param _cre8orsNFT The address of the NFT contract. (cre8ors)
    /// @param _minter The address of the minter. (FriendsAndFamilyMinter)
    constructor(address _cre8orsNFT, address _minter) ERC5643(_cre8orsNFT, _minter) { }

    /*//////////////////////////////////////////////////////////////
                     USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISubscription
    function isSubscriptionValid(uint256 tokenId) public view override returns (bool) {
        return expiresAt(tokenId) > block.timestamp;
    }

    /// @inheritdoc ISubscription
    function validateSubscription(uint256 tokenId) public view override returns (bool) {
        bool isValid = isSubscriptionValid(tokenId);

        if (!isValid) {
            revert InvalidSubscription();
        }

        return isValid;
    }

    /*//////////////////////////////////////////////////////////////
                   USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISubscription
    function renewSubscriptionWithERC20Payment(
        uint256 tokenId,
        uint64 duration,
        address erc20
    )
        external
        payable
        override
    {
        _validateCallerAsOwnerOrApproved({ caller: msg.sender, tokenId: tokenId });

        _handleERC20PaymentSubscriptionUpdate(tokenId, duration, erc20);
    }

    /*//////////////////////////////////////////////////////////////
                    ONLY-ADMIN NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the renewability status of subscriptions.
    /// @dev This function can only be called by the admin.
    /// @param renewable Boolean flag to indicate if subscriptions are renewable.
    function setRenewable(bool renewable) external onlyAdmin {
        _renewable = renewable;
    }

    /// @notice Sets the minimum duration for subscription renewal.
    /// @dev This function can only be called by the admin.
    /// @param duration The minimum duration (in seconds) for subscription renewal.
    function setMinRenewalDuration(uint64 duration) external onlyAdmin {
        _setMinimumRenewalDuration(duration);
    }

    /// @notice Sets the maximum duration for subscription renewal.
    /// @dev This function can only be called by the admin.
    /// @param duration The maximum duration (in seconds) for subscription renewal.
    function setMaxRenewalDuration(uint64 duration) external onlyAdmin {
        _setMaximumRenewalDuration(duration);
    }

    /*//////////////////////////////////////////////////////////////
                   ONLY-MINTER NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /*//////////   updateSubscriptionForFree variants   //////////*/

    /// @inheritdoc ISubscription
    function updateSubscriptionForFree(uint256 tokenId, uint64 duration) external override onlyMinter {
        _validateDurationBetweenMinAndMax(duration);
        _updateSubscriptionExpiration(tokenId, duration);
    }

    /// @inheritdoc ISubscription
    function updateSubscriptionForFree(uint256[] calldata tokenIds, uint64 duration) external override onlyMinter {
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];

            _validateDurationBetweenMinAndMax(duration);
            _updateSubscriptionExpiration(tokenId, duration);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISubscription
    function updateSubscriptionForFree(
        uint256[] calldata tokenIds,
        uint64[] calldata durations
    )
        external
        override
        onlyMinter
    {
        if (tokenIds.length != durations.length) revert LengthMismatch();

        uint256 tokenId;
        uint64 duration;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            duration = durations[i];

            _validateDurationBetweenMinAndMax(duration);
            _updateSubscriptionExpiration(tokenId, duration);

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////   updateSubscription variants   /////////////*/

    /// @inheritdoc ISubscription
    function updateSubscription(uint256 tokenId, uint64 duration) external payable override onlyMinter {
        _validateDurationBetweenMinAndMax(duration);

        _validateRenewalPrice(msg.value, duration);

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    /// @inheritdoc ISubscription
    function updateSubscription(uint256[] calldata tokenIds, uint64 duration) external payable override onlyMinter {
        if (tokenIds.length == 0) revert InvalidLength();

        uint256 val = msg.value;
        _validateRenewalPrice(val, uint64(tokenIds.length * duration));

        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];

            _validateDurationBetweenMinAndMax(duration);

            _updateSubscriptionExpiration(tokenId, duration);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISubscription
    function updateSubscription(
        uint256[] calldata tokenIds,
        uint64[] calldata durations
    )
        external
        payable
        override
        onlyMinter
    {
        if (tokenIds.length != durations.length) revert LengthMismatch();

        uint256 totalDuration; // to prevent overflow
        for (uint256 i = 0; i < durations.length;) {
            totalDuration += durations[i];

            unchecked {
                ++i;
            }
        }

        _validateRenewalPrice(msg.value, uint64(totalDuration));

        uint256 tokenId;
        uint64 duration;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            duration = durations[i];

            _validateDurationBetweenMinAndMax(duration);

            _updateSubscriptionExpiration(tokenId, duration);

            unchecked {
                ++i;
            }
        }
    }

    /*//////   updateSubscriptionWithERC20Payment variants   /////*/

    /// @inheritdoc ISubscription
    function updateSubscriptionWithERC20Payment(
        uint256 tokenId,
        uint64 duration,
        address erc20
    )
        external
        override
        onlyMinter
    {
        _handleERC20PaymentSubscriptionUpdate(tokenId, duration, erc20);
    }

    /// @inheritdoc ISubscription
    function updateSubscriptionWithERC20Payment(
        uint256[] calldata tokenIds,
        uint64 duration,
        address erc20
    )
        external
        override
        onlyMinter
    {
        if (tokenIds.length == 0) revert InvalidLength();
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];

            _handleERC20PaymentSubscriptionUpdate(tokenId, duration, erc20);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISubscription
    function updateSubscriptionWithERC20Payment(
        uint256[] calldata tokenIds,
        uint64[] calldata durations,
        address erc20
    )
        external
        override
        onlyMinter
    {
        if (tokenIds.length != durations.length) revert LengthMismatch();

        uint256 totalDuration; // to prevent overflow
        for (uint256 i = 0; i < durations.length;) {
            totalDuration += durations[i];

            unchecked {
                ++i;
            }
        }

        // ERC-20 Specific pre-flight checks
        _handleERC20Payment(uint64(totalDuration), erc20);

        uint256 tokenId;
        uint64 duration;

        for (uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            duration = durations[i];

            _validateDurationBetweenMinAndMax(duration);

            _updateSubscriptionExpiration(tokenId, duration);

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                       INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC5643
    function _isRenewable() internal view override returns (bool) {
        return _renewable;
    }

    /// @inheritdoc ERC5643
    function _getRenewalPrice(uint64 duration) internal view override returns (uint256) {
        return duration * nativeCurrencyPrice;
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal function to handle ERC20 token payment for subscription and extend subscription.
    /// @param tokenId The unique identifier of the subscription token.
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param erc20 The address of the ERC20 token to use for payment.
    function _handleERC20PaymentSubscriptionUpdate(uint256 tokenId, uint64 duration, address erc20) internal {
        _validateDurationBetweenMinAndMax(duration);

        // ERC-20 Specific pre-flight checks
        _handleERC20Payment(duration, erc20);

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    /// @dev Internal function to handle ERC20 token payment with pre-flight checks.
    /// @param duration The duration (in seconds) to extend the subscription for.
    /// @param erc20 The address of the ERC20 token to use for payment.
    function _handleERC20Payment(uint64 duration, address erc20) internal {
        address msgSender = msg.sender;
        address addressThis = address(this);

        uint256 tokensQtyToTransfer = chargeAmountForERC20(erc20) * duration;
        IERC20 payableToken = IERC20(erc20);

        if (payableToken.balanceOf(msgSender) < tokensQtyToTransfer) revert ERC20InsufficientBalance();
        if (payableToken.allowance(msgSender, addressThis) < tokensQtyToTransfer) {
            revert ERC20InsufficientAllowance();
        }

        ERC20TransferHelper.safeTransferFrom(IERC20(erc20), msgSender, addressThis, tokensQtyToTransfer);
    }
}
