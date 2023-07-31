// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC5643 } from "./interfaces/IERC5643.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { console2 } from "forge-std/console2.sol";

error RenewalTooShort();
error RenewalTooLong();
error InsufficientPayment();
error SubscriptionNotRenewable();
error InvalidTokenId();
error CallerNotOwnerNorApproved();

error CallerNotERC721();
error ReceiveNotAllowed();
error CalledWithOutData();

contract Subscription is IERC5643 {
    mapping(uint256 tokenId => uint64 expiresAt) private _expirations;

    uint64 private _minimumRenewalDuration;
    uint64 private _maximumRenewalDuration;

    // crea8ors contract
    IERC721 public erc721;

    bool private _renewable;

    constructor(IERC721 erc721_) {
        erc721 = erc721_;
    }

    fallback(bytes calldata input) external payable returns (bytes memory) {
        // console2.log("msg.sender: ", msg.sender);
        // console2.logBytes(input);

        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)

        // check that caller is erc721 otherwise revert
        if (msg.sender != address(erc721)) revert CallerNotERC721();

        // check data length
        if (input.length == 0) revert CalledWithOutData();

        // console2.log("here");

        // Decode the msg.data/input and extract the parameter
        uint256 tokenId = abi.decode(input, (uint256));
        // console2.log("tokenId: ", tokenId);

        // check if tokenId is valid
        if (tokenId == 0) revert InvalidTokenId();

        bool res = isSubscriptionValid(tokenId);
        // console2.log("isSubscriptionValid res: ", res);

        return abi.encode(res);
    }

    receive() external payable {
        revert ReceiveNotAllowed();
    }

    function isSubscriptionValid(uint256 tokenId) public view returns (bool) {
        return _expirations[tokenId] > block.timestamp;
    }

    function renewSubscription(uint256 tokenId, uint64 duration) external payable virtual override {
        // console2.log("msg.sender: ", msg.sender);
        // console2.log("tokenId: ", tokenId);
        // console2.log("duration: ", duration);

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
        if (msg.value < _getRenewalPrice(tokenId, duration)) {
            revert InsufficientPayment();
        }

        // extend subscription
        _extendSubscription(tokenId, duration);
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

    function setRenewable(bool renewable_) external {
        _renewable = renewable_;
    }

    function setMinimumRenewalDuration(uint64 duration) external {
        _setMinimumRenewalDuration(duration);
    }

    function setMaximumRenewalDuration(uint64 duration) external {
        _setMaximumRenewalDuration(duration);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC5643).interfaceId || erc721.supportsInterface(interfaceId);
    }

    // MUST ONLY BE CALLABLE BY ERC721 CONTRACT
    function extendSubscription(uint256 tokenId, uint64 duration) external {
        if (msg.sender != address(erc721)) revert CallerNotERC721();
        _extendSubscription(tokenId, duration);
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
    // solhint-disable-next-line
    function _isRenewable(uint256 tokenId) internal view virtual returns (bool) {
        return _renewable;
    }

    /**
     * @dev Gets the price to renew a subscription for `duration` seconds for
     * a given tokenId. This should be overridden in implementing contracts.
     */
    // solhint-disable-next-line
    function _getRenewalPrice(uint256 tokenId, uint64 duration) internal view virtual returns (uint256) {
        return 0.1 ether;
    }

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
}
