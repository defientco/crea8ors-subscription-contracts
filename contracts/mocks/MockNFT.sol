// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISubscription } from "../interfaces/ISubscription.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC721DropMinimal {
    /// @dev Getter for admin role associated with the contract to handle metadata
    /// @return boolean if address is admin
    function isAdmin(address user) external view returns (bool);
}

interface IMockNFT {
    error SubscriptionCannotBeZeroAddress();
    error Access_MissingRoleOrAdmin(bytes32 role);

    function adminMint(address to, uint256 tokenId) external returns (uint256);
    function adminBurn(uint256 tokenId) external returns (uint256);
    function mint(address to, uint256 tokenId) external returns (uint256);
    function burn(uint256 tokenId) external returns (uint256);
}

contract MockNFTAdmin is AccessControl {
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    constructor(address _initialOwner) {
        // Setup the owner role
        _setupRole(DEFAULT_ADMIN_ROLE, _initialOwner);
    }
}

// cre8ors nft
contract MockNFT is IMockNFT, IERC721DropMinimal, Ownable, MockNFTAdmin, ERC721 {
    // REQUIRED
    address public subscription;
    bool public isSubscriptionEnabled;

    uint256 public totalSupply;

    constructor(bool _enableSubscription, address _initialOwner) MockNFTAdmin(_initialOwner) ERC721("", "") {
        isSubscriptionEnabled = _enableSubscription;
    }

    function adminMint(address to, uint256 tokenId) public onlyOwner returns (uint256) {
        return mint(to, tokenId);
    }

    function adminBurn(uint256 tokenId) public onlyOwner returns (uint256) {
        return burn(tokenId);
    }

    function mint(address to, uint256 tokenId) public returns (uint256) {
        _mint(to, tokenId);
        totalSupply++;
        return tokenId;
    }

    function burn(uint256 tokenId) public returns (uint256) {
        _burn(tokenId);
        totalSupply--;
        return tokenId;
    }

    // REQUIRED
    // override ownerOf
    function ownerOf(uint256 tokenId) public view override returns (address) {
        // external call to subscription if it is enabled and present
        if (isSubscriptionEnabled && subscription != address(0)) {
            bool isSubscriptionValid = ISubscription(subscription).isSubscriptionValid(tokenId);

            // if subscription expired
            if (!isSubscriptionValid) {
                return address(0);
            }
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

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC721).interfaceId == interfaceId;
    }

    // JUST FOR TESTING

    function isAdmin(address user) public view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }
}
