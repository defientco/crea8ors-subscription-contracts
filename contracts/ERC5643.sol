// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC5643 } from "./interfaces/IERC5643.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();
error InvalidTokenId();
error CallerNotOwnerNorApproved();

abstract contract ERC5643 is IERC5643 {
    mapping(uint256 tokenId => uint64 expiresAt) private _expirations;

    uint64 private _minimumRenewalDuration;
    uint64 private _maximumRenewalDuration;

    // crea8ors contract
    IERC721 public erc721;

    constructor(IERC721 erc721_) {
        erc721 = erc721_;
    }

    function renewSubscription(uint256 tokenId, uint64 duration) external payable virtual override {
        // only owner of the token id can call this
        // isApprovedOrOwner in crea8ors ??
        // or write a custom function ??
        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert CallerNotOwnerNorApproved();
        }

        // check duration
        if (duration < _minimumRenewalDuration) {
            revert RenewalTooShort();
        } else if (_maximumRenewalDuration != 0 && duration > _maximumRenewalDuration) {
            revert RenewalTooLong();
        }

        // check msg.value

        // extend subscription
    }

    function cancelSubscription(uint256 tokenId) external payable virtual override {
        // only owner of the token id can call this
        // isApprovedOrOwner in crea8ors ??
        // or write a custom function ??
        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert CallerNotOwnerNorApproved();
        }

        delete _expirations[tokenId];

        emit SubscriptionUpdate(tokenId, 0);
    }

    function expiresAt(uint256 tokenId) external view virtual override returns (uint64) {
        // _exists cannot be used as internal
        // create custom function ?
        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert InvalidTokenId();
        }
        return _expirations[tokenId];
    }

    function isRenewable(uint256 tokenId) external view virtual override returns (bool) {
        // _exists cannot be used as internal
        // create custom function ?
        if (msg.sender != erc721.ownerOf(tokenId)) {
            revert InvalidTokenId();
        }
        return _isRenewable(tokenId);
    }

    function _extendSubscription(uint256 tokenId, uint64 duration) internal virtual {
        // will auto revert if tokenId does not exists because of ownerOf

        uint64 currentExpiration = _expirations[tokenId];
        uint64 newExpiration;
        if ((currentExpiration == 0) || (currentExpiration < block.timestamp)) {
            newExpiration = uint64(block.timestamp) + duration;
        } else {
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
    function _isRenewable(uint256 tokenId) internal view virtual returns (bool);

    /**
     * @dev Internal function to set the minimum renewal duration.
     */
    function _setMinimumRenewalDuration(uint64 duration) internal virtual {
        _minimumRenewalDuration = duration;
    }

    /**
     * @dev Internal function to set the maximum renewal duration.
     */
    function _setMaximumRenewalDuration(uint64 duration) internal virtual {
        _maximumRenewalDuration = duration;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC5643).interfaceId || erc721.supportsInterface(interfaceId);
    }
}
