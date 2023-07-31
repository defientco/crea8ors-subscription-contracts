// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { console2 } from "forge-std/console2.sol";

error SubscriptionAddressInvalid();
error ExternalCallUnsuccessful();
error SubscriptionExpired();

contract MockERC721 is ERC721 {
    uint256 public totalSupply;

    address public subscription;
    bool public isSubscriptionEnabled;

    constructor(bool enable) ERC721("Mock ERC721", "MERC721") {
        isSubscriptionEnabled = enable;
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
        totalSupply++;
    }

    function subscribe(uint256 tokenId, uint64 duration) public {
        subscription.call(abi.encodeWithSignature("extendSubscription(uint256,uint64)", tokenId, duration));
    }

    function mintWithSubscription(address to, uint256 tokenId, uint64 duration) public {
        mint(to, tokenId);
        subscribe(tokenId, duration);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
        totalSupply--;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        // if subscription enabled then run subscription flow
        if (isSubscriptionEnabled) {
            // check if subscription address valid
            if (subscription == address(0)) revert SubscriptionAddressInvalid();

            (bool success, bytes memory res) = subscription.staticcall(abi.encode(tokenId));

            console2.log("MockERC721 res: ");
            console2.logBytes(res);

            if (!success) revert ExternalCallUnsuccessful();

            bool isSubValid = abi.decode(res, (bool));

            console2.log("isSubValid: ", isSubValid);

            if (!isSubValid) revert SubscriptionExpired();
        }

        return super.ownerOf(tokenId);
    }

    function setSubscription(address s) external {
        subscription = s;
    }

    function toggleSubscription() external {
        isSubscriptionEnabled = !isSubscriptionEnabled;
    }
}
