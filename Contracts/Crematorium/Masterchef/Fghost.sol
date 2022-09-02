// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Contracts/Support/ERC20.sol";
import "Contracts/Support/IERC20.sol";
import "Contracts/Support/utils/Ownable.sol";

contract tGhost is ERC20, Ownable{
    uint256 private _totalSupply;
 mapping(address => uint256) private _balances;
 uint256 public _maxSupply;

    constructor(uint256 initialSupply, uint256 maxSupply) ERC20("fGhost", "FGHST"){
        _mint(msg.sender, initialSupply);
        _maxSupply = maxSupply;
    }
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");
        if (amount > _maxSupply - _totalSupply){
            amount = _maxSupply - _totalSupply;
        }

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function mint(address account, uint256 amount) external onlyOwner{
         require(account != address(0), "ERC20: mint to the zero address");
        if(amount > _maxSupply - _totalSupply){
            amount = _maxSupply - _totalSupply; 
        }

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function maximumSupply() public view returns(uint256){
        return _maxSupply;
    }
}