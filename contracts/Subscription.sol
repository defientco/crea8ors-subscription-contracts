// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC5643 } from "./interfaces/IERC5643.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { console2 } from "forge-std/console2.sol";
import { PaymentSystem } from "./abstracts/PaymentSystem.sol";
import { ERC20TransferHelper } from "./libraries/ERC20TransferHelper.sol";
import { ISubscription } from "./interfaces/ISubscription.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();
error InvalidTokenId();
error CallerNotOwnerNorApproved();

error CallerNotERC721();
error ReceiveNotAllowed();
error CalledWithOutData();

error InvalidSubscription();
error Access_OnlyMinter();

contract Subscription is IERC5643, ISubscription, PaymentSystem {
    uint64 public constant DEFAULT_SUBSCRIPTION_DURATION = 365 days;
    mapping(uint256 tokenId => uint64 expiresAt) private _expirations;

    uint64 public minRenewalDuration;
    uint64 public maxRenewalDuration; // 0 value means lifetime extension

    bool private _renewable;

    constructor(address _cre8orsNFT, address _minter) PaymentSystem(_cre8orsNFT, _minter) { }

    function isSubscriptionValid(uint256 tokenId) public view override returns (bool) {
        return _expirations[tokenId] > block.timestamp;
    }

    // crea8ors nft will call validateSubscription in ownerOf and then super.ownerOf()
    function validateSubscription(uint256 tokenId) public view override returns (bool) {
        bool flag = isSubscriptionValid(tokenId);

        if (flag) {
            revert InvalidSubscription();
        }

        return flag;
    }

    function renewSubscription(uint256 tokenId, uint64 duration) external payable virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CallerNotOwnerNorApproved();
        }

        // check duration
        if (duration < minRenewalDuration) {
            revert RenewalTooShort();
        } else if (maxRenewalDuration != 0 && duration > maxRenewalDuration) {
            revert RenewalTooLong();
        }

        // check msg.value
        if (msg.value < _getRenewalPrice(tokenId, duration)) {
            revert InsufficientPayment();
        }

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    function renewSubscriptionWithERC20Payment(
        uint256 tokenId,
        uint64 duration,
        address erc20
    )
        external
        payable
        override
    {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CallerNotOwnerNorApproved();
        }

        // check duration
        if (duration < minRenewalDuration) {
            revert RenewalTooShort();
        } else if (maxRenewalDuration != 0 && duration > maxRenewalDuration) {
            revert RenewalTooLong();
        }

        // ERC-20 Specific pre-flight checks
        uint256 tokensQtyToTransfer = chargeAmountForERC20(erc20) * duration;
        IERC20 payableToken = IERC20(erc20);

        if (payableToken.balanceOf(msg.sender) < tokensQtyToTransfer) revert ERC20InsufficientBalance();
        if (payableToken.allowance(msg.sender, address(this)) < tokensQtyToTransfer) {
            revert ERC20InsufficientAllowance();
        }

        ERC20TransferHelper.safeTransferFrom(IERC20(erc20), msg.sender, address(this), tokensQtyToTransfer);

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    function cancelSubscription(uint256 tokenId) external payable virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert CallerNotOwnerNorApproved();
        }

        delete _expirations[tokenId];

        emit SubscriptionUpdate(tokenId, 0);
    }

    function expiresAt(uint256 tokenId) external view virtual override returns (uint64) {
        return _expirations[tokenId];
    }

    function isRenewable(uint256 tokenId) external view virtual override returns (bool) {
        return _isRenewable(tokenId);
    }

    function setRenewable(bool renewable_) external onlyAdmin {
        _renewable = renewable_;
    }

    function setMinRenewalDuration(uint64 duration) external onlyAdmin {
        _setMinimumRenewalDuration(duration);
    }

    function setMaxRenewalDuration(uint64 duration) external onlyAdmin {
        _setMaximumRenewalDuration(duration);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC5643).interfaceId || IERC721(cre8orsNFT).supportsInterface(interfaceId);
    }

    function updateSubscriptionForFree(uint256 tokenId, uint64 duration) external onlyMinter {
        _updateSubscriptionExpiration(tokenId, duration);
    }

    function updateSubscription(uint256 tokenId, uint64 duration) external payable override onlyMinter {
        // check duration
        if (duration < minRenewalDuration) {
            revert RenewalTooShort();
        } else if (maxRenewalDuration != 0 && duration > maxRenewalDuration) {
            revert RenewalTooLong();
        }

        // check msg.value
        if (msg.value < _getRenewalPrice(tokenId, duration)) {
            revert InsufficientPayment();
        }

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

    function updateSubscriptionWithERC20Payment(
        uint256 tokenId,
        uint64 duration,
        address erc20
    )
        external
        override
        onlyMinter
    {
        // check duration
        if (duration < minRenewalDuration) {
            revert RenewalTooShort();
        } else if (maxRenewalDuration != 0 && duration > maxRenewalDuration) {
            revert RenewalTooLong();
        }

        // ERC-20 Specific pre-flight checks
        uint256 tokensQtyToTransfer = chargeAmountForERC20(erc20) * duration;
        IERC20 payableToken = IERC20(erc20);

        if (payableToken.balanceOf(msg.sender) < tokensQtyToTransfer) revert ERC20InsufficientBalance();
        if (payableToken.allowance(msg.sender, address(this)) < tokensQtyToTransfer) {
            revert ERC20InsufficientAllowance();
        }

        ERC20TransferHelper.safeTransferFrom(IERC20(erc20), msg.sender, address(this), tokensQtyToTransfer);

        // extend subscription
        _updateSubscriptionExpiration(tokenId, duration);
    }

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
            if (!_isRenewable(tokenId)) {
                revert SubscriptionNotRenewable();
            }
            newExpiration = currentExpiration + duration;
        }

        _expirations[tokenId] = newExpiration;

        emit SubscriptionUpdate(tokenId, newExpiration);
    }

    /**
     * @dev Internal function to determine renewability. Implementing contracts
     * should override this function if renewabilty should be disabled for all or
     * some tokens.
     */
    function _isRenewable(uint256 /*tokenId*/ ) internal view virtual returns (bool) {
        return _renewable;
    }

    /**
     * @dev Gets the price to renew a subscription for `duration` seconds for
     * a given tokenId. This should be overridden in implementing contracts.
     */
    // solhint-disable-next-line
    function _getRenewalPrice(uint256 tokenId, uint64 duration) internal view virtual returns (uint256) {
        return duration * nativeCurrencyPrice;
    }

    /**
     * @dev Internal function to set the minimum renewal duration.
     */
    function _setMinimumRenewalDuration(uint64 duration) internal virtual {
        minRenewalDuration = duration;
    }

    /**
     * @dev Internal function to set the maximum renewal duration.
     */
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
