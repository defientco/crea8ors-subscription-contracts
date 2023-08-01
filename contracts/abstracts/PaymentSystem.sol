// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20TransferHelper } from "../libraries/ERC20TransferHelper.sol";
import { Minter } from "./Minter.sol";

abstract contract PaymentSystem is Minter {
    struct ERC20State {
        bool isActive;
        uint256 chargeAmount; // pricePerSecond
    }

    mapping(address erc20Address => ERC20State state) private _erc20State;

    bool public erc20MintingEnabled;
    uint256 public nativeCurrencyPrice; // pricePerSecond

    error ValueCannotBeZero();
    error ERC20InsufficientBalance();
    error ERC20InsufficientAllowance();
    error ERC20NotActive();
    error ETHTransferFailed();

    // solhint-disable-next-line no-empty-blocks
    constructor(address _crea8orsNFT, address _minter) Minter(_crea8orsNFT, _minter) { }

    function setNativeCurrencyPrice(uint256 _newPrice) external onlyAdmin {
        nativeCurrencyPrice = _newPrice;
    }

    function withdrawNativeCurrency(address _to) external onlyAdmin {
        if (address(this).balance == 0) revert ValueCannotBeZero();
        _withdraw(_to, address(this).balance);
    }

    function withdrawERC20(address _to, address _erc20Contract, uint256 _amountToWithdraw) external onlyAdmin {
        if (_amountToWithdraw == 0) revert ValueCannotBeZero();

        IERC20 erc20Contract = IERC20(_erc20Contract);

        if (erc20Contract.balanceOf(address(this)) < _amountToWithdraw) {
            revert ERC20InsufficientBalance();
        }

        ERC20TransferHelper.safeTransfer(erc20Contract, _to, _amountToWithdraw);
    }

    function addOrUpdateERC20ContractAsPayment(
        address _erc20ERC20Contract,
        bool _isActive,
        uint256 _chargeAmountInERC20s
    )
        external
        onlyAdmin
    {
        _erc20State[_erc20ERC20Contract] = ERC20State(_isActive, _chargeAmountInERC20s);
    }

    function toggleERC20ContractAsPayment(address _erc20ERC20Contract) external onlyAdmin {
        _erc20State[_erc20ERC20Contract].isActive = !_erc20State[_erc20ERC20Contract].isActive;
    }

    function toggleERC20Minting() external onlyAdmin {
        erc20MintingEnabled = !erc20MintingEnabled;
    }

    function isERC20ActiveForPayments(address _erc20ERC20Contract) public view returns (bool) {
        return _erc20State[_erc20ERC20Contract].isActive;
    }

    function chargeAmountForERC20(address _erc20ERC20Contract) public view returns (uint256) {
        if (!isERC20ActiveForPayments(_erc20ERC20Contract)) revert ERC20NotActive();
        return _erc20State[_erc20ERC20Contract].chargeAmount;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success,) = payable(_address).call{ value: _amount }("");
        if (!success) revert ETHTransferFailed();
    }
}
