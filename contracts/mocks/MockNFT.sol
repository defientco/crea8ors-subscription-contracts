// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ISubscription } from "../interfaces/ISubscription.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IMockNFT {
    error SubscriptionCannotBeZeroAddress();

    function mint(address to, uint256 tokenId) external returns (uint256);
    function burn(uint256 tokenId) external returns (uint256);
}

// cre8ors nft
contract MockNFT is IMockNFT, Ownable, ERC721 {
    // REQUIRED
    address public subscription;
    bool public isSubscriptionEnabled;

    uint256 public totalSupply;

    constructor(address _subscription) ERC721("", "") {
        subscription = _subscription;
    }

    function mint(address to, uint256 tokenId) public onlyOwner returns (uint256) {
        _mint(to, tokenId);
        totalSupply++;
        return tokenId;
    }

    function burn(uint256 tokenId) public onlyOwner returns (uint256) {
        _burn(tokenId);
        totalSupply--;
        return tokenId;
    }

    // REQUIRED
    // override ownerOf
    function ownerOf(uint256 tokenId) public view override returns (address) {
        // external call to subscription if it is enabled and present
        if (isSubscriptionEnabled && subscription != address(0)) {
            // handles revert for us
            ISubscription(subscription).validateSubscription(tokenId);
        }
        return super.ownerOf(tokenId);
    }

    // ONLY_ADMIN REQUIRED
    function setSubscription(address s) external onlyOwner {
        if (s == address(0)) revert SubscriptionCannotBeZeroAddress();
        subscription = s;
    }

    // ONLY_ADMIN REQUIRED
    function toggleSubscription() external onlyOwner {
        isSubscriptionEnabled = !isSubscriptionEnabled;
    }
}
