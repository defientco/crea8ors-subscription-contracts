// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Test } from "forge-std/Test.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MockMinter } from "contracts/mocks/MockMinter.sol";
import { MockNFT } from "contracts/mocks/MockNFT.sol";
import { Subscription } from "contracts/Subscription.sol";

// solhint-disable-next-line
import { console2 } from "forge-std/console2.sol";

error SubscriptionExpired();

contract SubscriptionTest is Test {
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    address payable internal user = payable(address(0x12345));
    MockMinter internal mockMinter;
    MockNFT internal mockNFT;
    Subscription internal subscription;

    function setUp() public virtual {
        vm.label(user, "User");
        vm.deal(user, 10 ether);
        vm.startPrank(user);

        mockNFT = new MockNFT({
            _enableSubscription: true,
            _initialOwner: user
        });

        subscription = new Subscription({
            cre8orsNFT_: address(mockNFT),
            minRenewalDuration_: 1 days,
            pricePerSecond_: 38580246913 // Roughly calculates to 0.1 ether per 30 days
        });

        mockNFT.setSubscription(address(subscription));

        mockMinter = new MockMinter({_mockNFT: address(mockNFT), _subscription: address(subscription)});

        IAccessControl(mockNFT).grantRole(MINTER_ROLE, address(mockMinter));

        Ownable(address(mockNFT)).transferOwnership(address(mockMinter));
    }

    function test_BasicSubscriptionModel() external {
        uint256 tokenId = 1;
        address owner;

        vm.warp(block.timestamp + 1 days);

        // mint nft for user(user)
        mockMinter.freeMint(address(mockNFT), user, tokenId);

        // ownerOf returns correct user
        owner = mockNFT.ownerOf(tokenId);
        assertEq(owner, user);

        // 30 days passed
        vm.warp(block.timestamp + 30 days);

        owner = mockNFT.ownerOf(tokenId);
        assertEq(owner, address(0));
    }
}
