// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "Contracts/Support/ERC20.sol";
import "Contracts/Support/IERC20.sol";
import "Contracts/Support/utils/Ownable.sol";

contract fGhost is ERC20, Ownable{
    uint256 private _totalSupply;
 mapping(address => uint256) private _balances;
 uint256 private _maxSupply;

    constructor(uint256 initialSupply, uint256 maxSupply) ERC20("FGhost", "FGHST"){
        _mint(msg.sender, initialSupply);
        maxSupply = _maxSupply;
    }
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply <= _maxSupply, "ERC20: Insufficient Supply");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
}