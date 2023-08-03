// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { BaseScript } from "./Base.s.sol";
import { Subscription } from "contracts/Subscription.sol";
import { MockNFT } from "contracts/mocks/MockNFT.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySubscription is BaseScript {
    function run() public broadcast returns (Subscription subscription) {
        MockNFT mockNFT = new MockNFT({
            _enableSubscription: true,
            _initialOwner: msg.sender
        });

        subscription = new Subscription({
            cre8orsNFT_: address(mockNFT),
            minRenewalDuration_: 1 days,
            pricePerSecond_: 38580246913 // Roughly calculates to 0.1 ether per 30 days
        });

        mockNFT.setSubscription(address(subscription));
    }
}
