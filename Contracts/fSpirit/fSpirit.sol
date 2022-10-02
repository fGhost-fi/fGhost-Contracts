// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Contracts/Support/ERC20.sol";
import "Contracts/Support/IERC20.sol";
import "Contracts/Support/utils/Ownable.sol";

contract fSpirit is ERC20, Ownable{
    uint256 private _totalSupply;
 mapping(address => uint256) private _balances;
 

    constructor(uint256 initialSupply) ERC20("fSpirit", "FSPIRIT"){
        _mint(msg.sender, initialSupply);
    }
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");
     
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function mint(address account, uint256 amount) external onlyOwner{
         require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint amount) external override {
        _burn(account, amount);
    }
}