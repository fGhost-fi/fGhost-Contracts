//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Contracts/Support/SafeERC20.sol";
import "Contracts/Support/utils/Ownable.sol";

contract GhostFarmer is Ownable{
        using SafeERC20 for IERC20;
    
   event PayeeAdded(address account, uint256 shares);
   event PaymentReleased(address to, uint256 amount);

    address internal paymentToken;
    uint256 internal _totalShares;
    uint256 internal _totalTokenReleased;
    address[] internal _payees;
    mapping(address => uint256) internal _shares;
    mapping(address => uint256) internal _tokenReleased;
    uint256 internal slot;
constructor(
    address[] memory payees, 
    uint256[] memory shares_,
    address _paymentToken
) {
    require(
        payees.length == shares_.length,
        "GhostFarmer: payees and shares length mismatch"
    );
    require(payees.length > 0, "GhostFarmer: no payees");
    for (uint256 i = 0; i < payees.length; i++) {
        _addPayee(payees[i], shares_[i]);
    }
    paymentToken = _paymentToken;
}
function totalShares() external view returns (uint256) {
    return _totalShares;
}
function shares(address account) external view returns (uint256) {
    return _shares[account];
}
function payee(uint256 index) external view returns (address) {
    return _payees[index];
}
function _addPayee(address account, uint256 shares_) internal {
    require(
        account != address(0),
        "GhostFarmer: account is the zero address"
    );
    require(shares_ > 0, "TokenPaymentSplitter: shares are 0");
    require(
        _shares[account] == 0,
        "GhostFarmer: account already has shares"
    );
    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;

     emit PaymentReleased(account, payment);
}
function addPayee(address account, uint256 shares_) external onlyOwner {
    require(
        account != address(0),
        "GhostFarmer: account is the zero address"
    );
    require(shares_ > 0, "GhostFarmer: shares are 0");
    require(
        _shares[account] == 0,
        "GhostFarmer: account already has shares"
    );
    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
}
function push() public { 
    address account =  _payees[slot];
 require (_shares[account] > 0);
 uint256 i=0;
  uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
  uint256 payment = (tokenTotalReceived * _shares[account]) / _totalShares - _tokenReleased[account];
     _tokenReleased[account] = _tokenReleased[account] + payment;
    _totalTokenReleased = _totalTokenReleased + payment;
   while (i < _payees.length) {IERC20(paymentToken).safeTransfer(account, payment);
    slot ++;
    i ++;
    }
      emit PaymentReleased(account, payment);
}
 
}