// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test } from "forge-std/Test.sol";
import { MockERC721 } from "contracts/mocks/MockERC721.sol";
import { Subscription } from "contracts/Subscription.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { console2 } from "forge-std/console2.sol";

error SubscriptionExpired();

contract SubscriptionTest is Test {
    address payable internal user = payable(address(0x12345));
    MockERC721 internal mockERC721;
    Subscription internal subscription;

    function setUp() public virtual {
        vm.label(user, "User");
        vm.deal(user, 10 ether);
        vm.startPrank(user);

        mockERC721 = new MockERC721({enable: true});

        subscription = new Subscription({erc721_: IERC721(address(mockERC721))});

        MockERC721(mockERC721).setSubscription(address(subscription));
    }

    function testBasicSubscriptionModel() external {
        uint256 tokenId = 1;
        address owner;

        vm.warp(block.timestamp + 1 days);

        // mint nft for user(user)
        mockERC721.mintWithSubscription(user, tokenId, 2 days);

        // ownerOf returns correct user
        owner = mockERC721.ownerOf(tokenId);
        assertEq(owner, user);

        // 30 days passed
        vm.warp(block.timestamp + 30 days);

        // ownerOf reverts with SubscriptionExpired
        vm.expectRevert(SubscriptionExpired.selector);
        owner = mockERC721.ownerOf(tokenId);
    }
}
